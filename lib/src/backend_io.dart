// Non-web backend — used on Flutter/Dart targets that have `dart:io`
// (macOS, iOS, Linux, Windows, Android, desktop, VM). Selected via
// conditional import in [quicktype_dart.dart].
//
// Dispatches between the embedded QuickJS FFI runtime and the `quicktype`
// Node CLI (`Process.run`) per the caller's [GenerateTransport] choice.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'ffi/ffi_runtime.dart';
import 'models/type.dart';
import 'quicktype.dart';
import 'quicktype_dart.dart' show GenerateTransport, QuicktypeDart;
import 'utils/logging.dart';

/// Backend entry point. Platform-independent argument handling already
/// happened in [QuicktypeDart.generateFromString]; this function just
/// picks an execution path and runs it.
Future<String> generateFromString({
  required String label,
  required String json,
  required TargetType target,
  required Map<String, String> rendererOptions,
  required GenerateTransport transport,
}) async {
  final resolved = await _resolveTransport(transport);
  switch (resolved) {
    case GenerateTransport.ffi:
      final rt = await QtFfiRuntime.instance();
      return rt.generate(
        label: label,
        json: json,
        target: target,
        rendererOptions: rendererOptions,
      );
    case GenerateTransport.process:
      return _runViaProcess(
        label: label,
        json: json,
        target: target,
        rendererOptions: rendererOptions,
      );
    case GenerateTransport.auto:
      throw StateError('unreachable');
  }
}

Future<GenerateTransport> _resolveTransport(GenerateTransport requested) async {
  switch (requested) {
    case GenerateTransport.ffi:
      return GenerateTransport.ffi;
    case GenerateTransport.process:
      return GenerateTransport.process;
    case GenerateTransport.auto:
      if (await QtFfiRuntime.probe()) return GenerateTransport.ffi;
      return GenerateTransport.process;
  }
}

Future<String> _runViaProcess({
  required String label,
  required String json,
  required TargetType target,
  required Map<String, String> rendererOptions,
}) async {
  final exe = await _resolveQuicktypeExecutable();
  final tempDir = await Directory.systemTemp.createTemp('quicktype_dart_');
  try {
    final safeLabel = _sanitizeLabel(label);
    final sourceFile = File(p.join(tempDir.path, '$safeLabel.json'));
    final targetExt = target.extensions.first;
    final targetFile = File(p.join(tempDir.path, '$safeLabel$targetExt'));

    await sourceFile.writeAsString(json);

    final argv = <String>[
      '--src',
      sourceFile.path,
      '--src-lang',
      'json',
      '--lang',
      target.argName,
      '--out',
      targetFile.path,
    ];
    // Serialize renderer options as CLI flags. Boolean-style "false" values
    // become --no-<name>; "true" collapses to --<name>; everything else
    // is --<name> <value>.
    for (final entry in rendererOptions.entries) {
      if (entry.value == 'true') {
        argv.add('--${entry.key}');
      } else if (entry.value == 'false') {
        argv.add('--no-${entry.key}');
      } else {
        argv.addAll(['--${entry.key}', entry.value]);
      }
    }

    final timeout = QuicktypeDart.processTimeout;
    final ProcessResult result;
    try {
      result = await Process.run(exe, argv).timeout(timeout);
    } on TimeoutException {
      throw QuicktypeException(
        'quicktype subprocess timed out after ${timeout.inSeconds}s. '
        'Raise the limit via QuicktypeDart.processTimeout if generations '
        'legitimately take longer.',
        command: '$exe ${argv.join(' ')}',
      );
    } catch (e, st) {
      throw QuicktypeException(
        'Failed to run quicktype: $e',
        command: '$exe ${argv.join(' ')}',
        cause: e,
        stackTrace: st,
      );
    }

    if (result.exitCode != 0) {
      throw QuicktypeException(
        'quicktype exited with code ${result.exitCode}: ${result.stderr}',
        command: '$exe ${argv.join(' ')}',
        exitCode: result.exitCode,
      );
    }

    if (!targetFile.existsSync()) {
      throw QuicktypeException(
        'quicktype reported success but no output file was produced',
        command: '$exe ${argv.join(' ')}',
        exitCode: result.exitCode,
      );
    }

    return targetFile.readAsString();
  } finally {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (e) {
      Log.warning('Failed to clean up temp dir ${tempDir.path}: $e');
    }
  }
}

/// Resolves a usable `quicktype` executable, independent of caller CWD.
/// Checks the bundled `tool/node_modules/.bin/quicktype` first; falls back
/// to a `quicktype` found on `PATH`.
Future<String> _resolveQuicktypeExecutable() async {
  final bundled = await _resolveBundledExecutable();
  if (bundled != null) return bundled;

  final onPath = _findOnPath('quicktype');
  if (onPath != null) return onPath;

  throw QuicktypeException(
    'quicktype not found. Install it with `npm install -g quicktype`, or '
    'make sure the bundled binary exists at '
    '<package-root>/tool/node_modules/.bin/quicktype. Alternatively, use '
    '`transport: GenerateTransport.ffi` to run via the embedded '
    'QuickJS runtime.',
  );
}

Future<String?> _resolveBundledExecutable() async {
  try {
    final packageUri = await Isolate.resolvePackageUri(
      Uri.parse('package:quicktype_dart/quicktype_dart.dart'),
    );
    if (packageUri == null) return null;
    final packageRoot = p.dirname(p.dirname(packageUri.toFilePath()));
    final exe =
        p.join(packageRoot, 'tool', 'node_modules', '.bin', 'quicktype');
    return File(exe).existsSync() ? exe : null;
  } catch (_) {
    return null;
  }
}

String? _findOnPath(String name) {
  final pathEnv = Platform.environment['PATH'];
  if (pathEnv == null || pathEnv.isEmpty) return null;
  final separator = Platform.isWindows ? ';' : ':';
  final candidates =
      Platform.isWindows ? ['$name.cmd', '$name.exe', name] : [name];
  for (final dir in pathEnv.split(separator)) {
    if (dir.isEmpty) continue;
    for (final cand in candidates) {
      final full = p.join(dir, cand);
      if (File(full).existsSync()) return full;
    }
  }
  return null;
}

String _sanitizeLabel(String label) {
  final cleaned = label.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  if (cleaned.isEmpty) return 'Generated';
  if (RegExp(r'^[0-9]').hasMatch(cleaned)) return 'T_$cleaned';
  return cleaned;
}
