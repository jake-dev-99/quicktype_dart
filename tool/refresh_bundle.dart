// One-command regeneration of the embedded quicktype-core JS bundle.
//
// Runs the existing `native/bundle/build_bundle.sh` + `embed_bundle.py`
// pipeline under a single Dart entrypoint so contributors don't have to
// remember the two-step procedure. Outputs land in their normal places:
//
//   native/bundle/quicktype_bundle.js     (rebundled JS)
//   native/shim/bundle_data.c             (C byte arrays for embedding)
//
// Prereqs:
//   * Node / npm installed and `tool/node_modules/.bin/quicktype` present
//     (run `npm install` in tool/ first).
//   * Python 3 on PATH.
//   * `native/bundle/node_modules/` present (run `npm install` there).
//
// Usage:
//   dart run tool/refresh_bundle.dart
//
// Exit codes:
//   0 — bundle regenerated successfully.
//   1 — a prereq is missing or one of the child processes failed.
//   2 — script invoked incorrectly.

import 'dart:io';

import 'package:path/path.dart' as p;

void main(List<String> args) async {
  if (args.isNotEmpty) {
    stderr.writeln('tool/refresh_bundle.dart takes no arguments.');
    exit(2);
  }

  final repoRoot = _resolveRepoRoot();
  final bundleDir = p.join(repoRoot, 'native', 'bundle');
  final shimDir = p.join(repoRoot, 'native', 'shim');

  _requireBinaryOnPath('bash');
  _requireBinaryOnPath('python3');

  if (!Directory(p.join(bundleDir, 'node_modules')).existsSync()) {
    stderr.writeln(
      'refresh_bundle: native/bundle/node_modules/ is missing. '
      'Run `cd native/bundle && npm install` first.',
    );
    exit(1);
  }
  final buildScript = File(p.join(bundleDir, 'build_bundle.sh'));
  if (!buildScript.existsSync()) {
    stderr.writeln(
      'refresh_bundle: ${buildScript.path} missing. Is this the right repo?',
    );
    exit(1);
  }

  stdout.writeln('refresh_bundle: rebundling JS via esbuild…');
  final bundle = await Process.start(
    'bash',
    ['build_bundle.sh'],
    workingDirectory: bundleDir,
    mode: ProcessStartMode.inheritStdio,
  );
  final bundleExit = await bundle.exitCode;
  if (bundleExit != 0) {
    stderr.writeln('refresh_bundle: build_bundle.sh failed ($bundleExit).');
    exit(1);
  }

  stdout.writeln('refresh_bundle: embedding bundle + prelude into C…');
  final embed = await Process.start(
    'python3',
    [
      p.join(shimDir, 'embed_bundle.py'),
      p.join(bundleDir, 'prelude.js'),
      p.join(bundleDir, 'quicktype_bundle.js'),
      p.join(shimDir, 'bundle_data.c'),
    ],
    workingDirectory: repoRoot,
    mode: ProcessStartMode.inheritStdio,
  );
  final embedExit = await embed.exitCode;
  if (embedExit != 0) {
    stderr.writeln('refresh_bundle: embed_bundle.py failed ($embedExit).');
    exit(1);
  }

  stdout.writeln(
    'refresh_bundle: done. Rebuild native/ via '
    '`cmake -S native -B build/native && cmake --build build/native`.',
  );
}

String _resolveRepoRoot() {
  // Script lives at <repo>/tool/refresh_bundle.dart; walk up to the dir
  // containing pubspec.yaml as a sanity check (symlinks can mislead a
  // pure path-arithmetic approach).
  final scriptPath = Platform.script.toFilePath();
  final guess = p.dirname(p.dirname(scriptPath));
  if (!File(p.join(guess, 'pubspec.yaml')).existsSync()) {
    stderr.writeln(
      'refresh_bundle: could not locate repo root from '
      '$scriptPath (no pubspec.yaml at $guess).',
    );
    exit(2);
  }
  return guess;
}

void _requireBinaryOnPath(String name) {
  final sep = Platform.isWindows ? ';' : ':';
  final pathEnv = Platform.environment['PATH'] ?? '';
  final candidates =
      Platform.isWindows ? ['$name.exe', '$name.cmd', name] : [name];
  for (final dir in pathEnv.split(sep)) {
    if (dir.isEmpty) continue;
    for (final c in candidates) {
      if (File(p.join(dir, c)).existsSync()) return;
    }
  }
  stderr.writeln(
    'refresh_bundle: `$name` not found on PATH. Install it and retry.',
  );
  exit(1);
}
