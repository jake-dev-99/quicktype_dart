// Syncs the package version across every file that stamps it.
//
// `pubspec.yaml` is the source of truth. This script rewrites:
//   * lib/src/version.dart         → const String packageVersion = '<v>';
//   * android/build.gradle         → version = "<v>"
//   * ios/quicktype_dart.podspec   → s.version = '<v>'
//   * macos/quicktype_dart.podspec → s.version = '<v>'
//
// Exit codes:
//   0 — all files matched (or `--write` rewrote them to match pubspec).
//   1 — drift detected and we were invoked in check-only mode. Stderr
//       lists every file that needs updating.
//   2 — internal error (missing file, unparseable pubspec, etc).
//
// Usage:
//   dart run tool/sync_version.dart           # check mode — CI gate
//   dart run tool/sync_version.dart --write   # rewrite files to match
//
// Designed to run from the package root. Invoke via
// `dart run tool/sync_version.dart` from CI and as a pre-release step.

import 'dart:io';

const _pubspecPath = 'pubspec.yaml';

class _Target {
  _Target(this.path, this.pattern, this.replacement);

  /// Path relative to the package root.
  final String path;

  /// Regex matching the line(s) that must be rewritten. Must capture the
  /// current version in group 1 for diagnostics.
  final RegExp pattern;

  /// Function that produces the replacement line given the new version.
  final String Function(String version) replacement;
}

/// Every file that carries the package version. Keep in lockstep with
/// `pubspec.yaml` — adding a new stamped file means adding an entry here.
final List<_Target> _targets = [
  _Target(
    'lib/src/version.dart',
    RegExp(r"const String packageVersion = '([^']+)';"),
    (v) => "const String packageVersion = '$v';",
  ),
  _Target(
    'android/build.gradle',
    RegExp(r'version\s*=\s*"([^"]+)"'),
    (v) => 'version = "$v"',
  ),
  _Target(
    'ios/quicktype_dart.podspec',
    RegExp(r"s\.version\s*=\s*'([^']+)'"),
    (v) => "s.version          = '$v'",
  ),
  _Target(
    'macos/quicktype_dart.podspec',
    RegExp(r"s\.version\s*=\s*'([^']+)'"),
    (v) => "s.version          = '$v'",
  ),
];

void main(List<String> args) {
  final write = args.contains('--write');

  final pubspec = File(_pubspecPath);
  if (!pubspec.existsSync()) {
    stderr.writeln('sync_version: $_pubspecPath not found. Run from '
        'package root.');
    exit(2);
  }
  final versionMatch = RegExp(r'^version:\s*(.+)$', multiLine: true)
      .firstMatch(pubspec.readAsStringSync());
  if (versionMatch == null) {
    stderr.writeln('sync_version: no "version:" field in $_pubspecPath.');
    exit(2);
  }
  final version = versionMatch.group(1)!.trim();
  stdout.writeln('sync_version: pubspec declares $version');

  final drift = <String>[];
  for (final t in _targets) {
    final file = File(t.path);
    if (!file.existsSync()) {
      stderr.writeln('  ! ${t.path} missing; skipping');
      continue;
    }
    final content = file.readAsStringSync();
    final match = t.pattern.firstMatch(content);
    if (match == null) {
      stderr.writeln('  ! ${t.path} has no match for ${t.pattern.pattern}');
      exit(2);
    }
    final current = match.group(1)!;
    if (current == version) {
      stdout.writeln('  ✓ ${t.path}');
      continue;
    }
    drift.add('  ✗ ${t.path} is at $current (expected $version)');
    if (write) {
      final replaced = content.replaceFirst(t.pattern, t.replacement(version));
      file.writeAsStringSync(replaced);
    }
  }

  if (drift.isEmpty) {
    stdout.writeln('sync_version: all files in sync.');
    exit(0);
  }
  if (write) {
    stdout.writeln('sync_version: rewrote:');
    drift.forEach(stdout.writeln);
    exit(0);
  }
  stderr
    ..writeln('sync_version: drift detected:')
    ..writeAll(drift.map((l) => '$l\n'))
    ..writeln('Run `dart run tool/sync_version.dart --write` to fix locally.');
  exit(1);
}
