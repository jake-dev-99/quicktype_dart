// Best-effort temp-dir cleanup with a one-retry queue for Windows, where
// the child process may still hold file-level locks briefly after exit.
//
// Package-private. Used by backend_io's Process transport; lives in its
// own class so the sweep state can be reset in tests and inspected via
// `deferredCount`.

import 'dart:io';

import '../logging.dart';

/// Encapsulates the deferred-orphan set and the best-effort cleanup logic.
/// One sweeper per subsystem that creates temp dirs; share an instance
/// only when callers can tolerate cross-call retry.
class TempDirSweeper {
  /// Creates a sweeper with an empty deferred-orphan set.
  TempDirSweeper();

  final Set<String> _deferred = <String>{};

  /// Best-effort delete of [tempDir]. Before attempting, sweeps any
  /// previously-deferred orphans queued by prior [cleanup] calls whose
  /// first delete attempt failed (typically on Windows). Failures on
  /// [tempDir] itself get queued for the next invocation.
  void cleanup(Directory tempDir) {
    _sweepDeferred();
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (e) {
      _deferred.add(tempDir.path);
      Log.warning(
        'Failed to clean up temp dir ${tempDir.path}: $e. Will retry on '
        'next invocation.',
      );
    }
  }

  /// Number of paths currently awaiting a retry. Useful in tests.
  int get deferredCount => _deferred.length;

  void _sweepDeferred() {
    if (_deferred.isEmpty) return;
    final still = <String>{};
    for (final path in _deferred) {
      try {
        final dir = Directory(path);
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } catch (_) {
        still.add(path);
      }
    }
    _deferred
      ..clear()
      ..addAll(still);
  }
}
