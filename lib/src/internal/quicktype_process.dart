// Shared subprocess helpers for the Process transport. Used by both the
// facade's auto/process path (backend_io.dart) and the config-driven
// Quicktype orchestrator (quicktype.dart) so they agree on:
//
//   1. How the quicktype executable is located (bundled node_modules first,
//      then PATH). Nobody resolves relative to `Directory.current` any more.
//   2. How timeouts, launch failures, and command-line formatting surface
//      as QuicktypeException.
//
// dart:io only — never imported from backend_web.dart.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../facade.dart' show QuicktypeDart;
import '../quicktype.dart' show QuicktypeException;
import 'package_layout.dart';
import 'shell.dart';

/// Resolves the on-disk `quicktype` executable. Checks the bundled
/// `tool/node_modules/.bin/quicktype` (independent of caller CWD) and
/// falls back to a `PATH` lookup. Throws [QuicktypeException] when
/// neither is available so callers don't have to repeat the message.
Future<String> resolveQuicktypeExecutable() async {
  final bundled = await bundledQuicktypeExe();
  if (bundled != null) return bundled;
  final onPath = findOnPath('quicktype');
  if (onPath != null) return onPath;
  throw const QuicktypeException(
    'quicktype not found. Install it with `npm install -g quicktype`, or '
    'make sure the bundled binary exists at '
    '<package-root>/$bundledQuicktypeExeRelative. Alternatively, use '
    '`transport: GenerateTransport.ffi` to run via the embedded '
    'QuickJS runtime.',
  );
}

/// Locates [name] on the current `PATH`. Returns null if not found.
/// Honors platform-specific separators and Windows extensions.
String? findOnPath(String name) {
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

/// Runs the resolved quicktype CLI with [argv] and returns the
/// [ProcessResult]. The caller inspects `exitCode`/`stdout`/`stderr`.
///
/// Throws [QuicktypeException] when the subprocess can't be launched or
/// exceeds [timeout] (defaulting to [QuicktypeDart.processTimeout]).
/// Does *not* throw on non-zero exit codes — the caller decides how to
/// interpret those.
Future<ProcessResult> runQuicktypeProcess(
  List<String> argv, {
  Duration? timeout,
}) async {
  final exe = await resolveQuicktypeExecutable();
  final effectiveTimeout = timeout ?? QuicktypeDart.processTimeout;
  final commandStr = formatCommand(exe, argv);
  try {
    return await Process.run(exe, argv).timeout(effectiveTimeout);
  } on TimeoutException {
    throw QuicktypeException(
      'quicktype subprocess timed out after ${effectiveTimeout.inSeconds}s. '
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
}
