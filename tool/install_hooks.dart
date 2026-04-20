// Installs an opt-in `pre-commit` git hook that runs
// `dart format --set-exit-if-changed` and
// `dart analyze --fatal-infos --fatal-warnings` before every commit.
//
// Mirrors what CI enforces, so a commit that would fail the static
// job fails locally first instead of wasting a CI run.
//
// Usage:
//   dart run tool/install_hooks.dart           # install / overwrite
//   dart run tool/install_hooks.dart --check   # verify installed (exit 1 if not)
//   dart run tool/install_hooks.dart --remove  # delete the hook
//
// Never runs automatically — you have to invoke this script yourself.

import 'dart:io';

const _hookBody = r'''#!/usr/bin/env bash
# Installed by tool/install_hooks.dart. Remove with:
#   rm .git/hooks/pre-commit
# or:
#   dart run tool/install_hooks.dart --remove

set -e

echo 'pre-commit: dart format'
dart format --set-exit-if-changed lib test tool bin example

echo 'pre-commit: dart analyze'
dart analyze --fatal-infos --fatal-warnings
''';

void main(List<String> args) {
  const hookPath = '.git/hooks/pre-commit';

  if (args.contains('--remove')) {
    final f = File(hookPath);
    if (f.existsSync()) {
      f.deleteSync();
      stdout.writeln('install_hooks: removed $hookPath');
    } else {
      stdout.writeln('install_hooks: no hook at $hookPath');
    }
    return;
  }

  if (args.contains('--check')) {
    final f = File(hookPath);
    if (!f.existsSync()) {
      stderr.writeln('install_hooks: $hookPath not installed');
      exit(1);
    }
    if (f.readAsStringSync() != _hookBody) {
      stderr.writeln('install_hooks: $hookPath is out of date — re-run '
          '`dart run tool/install_hooks.dart` to refresh.');
      exit(1);
    }
    stdout.writeln('install_hooks: ok');
    return;
  }

  if (!Directory('.git').existsSync()) {
    stderr.writeln('install_hooks: .git/ not found. Run from the repo root.');
    exit(1);
  }
  Directory('.git/hooks').createSync(recursive: true);
  File(hookPath).writeAsStringSync(_hookBody);
  // Make executable on POSIX — Windows git handles bash hooks via
  // Git-for-Windows' bundled bash, so the mode bit is harmless there.
  if (!Platform.isWindows) {
    final chmod = Process.runSync('chmod', ['+x', hookPath]);
    if (chmod.exitCode != 0) {
      stderr.writeln(
        'install_hooks: chmod +x $hookPath failed '
        '(exit ${chmod.exitCode}): ${chmod.stderr}',
      );
      exit(1);
    }
  }
  stdout.writeln('install_hooks: installed $hookPath');
  stdout.writeln('Runs `dart format --set-exit-if-changed` and `dart analyze` '
      'before each commit.');
}
