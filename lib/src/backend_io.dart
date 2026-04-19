// Non-web backend — used on Flutter/Dart targets that have `dart:io`
// (macOS, iOS, Linux, Windows, Android, desktop, VM). Selected via
// conditional import in [quicktype_dart.dart].
//
// Dispatches between the embedded QuickJS FFI runtime and the `quicktype`
// Node CLI (`Process.run`) per the caller's [GenerateTransport] choice.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import 'facade.dart' show GenerateTransport, QuicktypeDart;
import 'ffi/ffi_runtime.dart';
import 'models/type.dart';
import 'quicktype.dart';
import 'utils/logging.dart';
import 'utils/paths.dart';
import 'utils/shell.dart';

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
    final commandStr = formatCommand(exe, argv);
    final ProcessResult result;
    try {
      result = await Process.run(exe, argv).timeout(timeout);
    } on TimeoutException {
      throw QuicktypeException(
        'quicktype subprocess timed out after ${timeout.inSeconds}s. '
        'Raise the limit via QuicktypeDart.processTimeout if generations '
        'legitimately take longer.',
        command: commandStr,
      );
    } catch (e, st) {
      throw QuicktypeException(
        'Failed to run quicktype: $e',
        command: commandStr,
        cause: e,
        stackTrace: st,
      );
    }

    if (result.exitCode != 0) {
      throw QuicktypeException(
        'quicktype exited with code ${result.exitCode}: ${result.stderr}',
        command: commandStr,
        exitCode: result.exitCode,
      );
    }

    // Surface any advisory output the child emitted on success. Previously
    // deprecation notices and compatibility warnings were discarded; they
    // now land on Log.info / Log.warning so callers can see them.
    final stdoutStr = result.stdout.toString();
    if (stdoutStr.trim().isNotEmpty) {
      Log.info(stdoutStr.trimRight());
    }
    final stderrStr = result.stderr.toString();
    if (stderrStr.trim().isNotEmpty) {
      Log.warning(stderrStr.trimRight());
    }

    if (!targetFile.existsSync()) {
      throw QuicktypeException(
        'quicktype reported success but no output file was produced',
        command: commandStr,
        exitCode: result.exitCode,
      );
    }

    return targetFile.readAsString();
  } finally {
    _cleanupTempDir(tempDir);
  }
}

/// Deletes [tempDir] best-effort, with one retry + queue for a later
/// sweep if the first attempt hits a Windows file-lock. The second-chance
/// sweep runs on the next `_runViaProcess` invocation via [_sweepOrphans].
void _cleanupTempDir(Directory tempDir) {
  _sweepOrphans();
  try {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  } catch (e) {
    _deferredOrphans.add(tempDir.path);
    Log.warning(
      'Failed to clean up temp dir ${tempDir.path}: $e. Will retry on '
      'next invocation.',
    );
  }
}

/// Paths queued for a second-chance cleanup pass. Windows can keep files
/// locked briefly after the subprocess exits; this lets the next run
/// reclaim them instead of leaking into the user's temp dir.
final Set<String> _deferredOrphans = <String>{};

void _sweepOrphans() {
  if (_deferredOrphans.isEmpty) return;
  final still = <String>{};
  for (final path in _deferredOrphans) {
    try {
      final dir = Directory(path);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (_) {
      still.add(path);
    }
  }
  _deferredOrphans
    ..clear()
    ..addAll(still);
}

/// Resolves a usable `quicktype` executable, independent of caller CWD.
/// Checks the bundled `tool/node_modules/.bin/quicktype` first; falls back
/// to a `quicktype` found on `PATH`.
Future<String> _resolveQuicktypeExecutable() async {
  final bundled = await bundledQuicktypeExe();
  if (bundled != null) return bundled;

  final onPath = _findOnPath('quicktype');
  if (onPath != null) return onPath;

  throw const QuicktypeException(
    'quicktype not found. Install it with `npm install -g quicktype`, or '
    'make sure the bundled binary exists at '
    '<package-root>/$bundledQuicktypeExeRelative. Alternatively, use '
    '`transport: GenerateTransport.ffi` to run via the embedded '
    'QuickJS runtime.',
  );
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

/// Makes [label] safe to use as a filename stem. Non-alphanumeric chars
/// collapse to `_`; a leading digit gets a `T_` prefix. When any
/// substitution actually happened, a short content-hash suffix is
/// appended so two different inputs that sanitize to the same string
/// (e.g. `'User:Data'` and `'User-Data'`) don't silently collide on
/// disk.
String _sanitizeLabel(String label) {
  final cleaned = label.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  final modified = cleaned != label || cleaned.isEmpty;
  final base = cleaned.isEmpty
      ? 'Generated'
      : RegExp(r'^[0-9]').hasMatch(cleaned)
          ? 'T_$cleaned'
          : cleaned;
  if (!modified) return base;
  final hash =
      crypto.sha1.convert(utf8.encode(label)).toString().substring(0, 6);
  return '${base}_$hash';
}
