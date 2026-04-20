// Parses `coverage/lcov.info` and enforces minimum line-coverage
// thresholds. Invoked from CI after `dart test --coverage` has
// produced the lcov file.
//
// Thresholds:
//   * Overall lib/ line coverage  ≥ 80%
//   * Critical-path files         ≥ 90%
//     - lib/src/backend_io.dart
//     - lib/src/backend_web.dart
//     - lib/src/config.dart
//     - lib/src/ffi/native_bundle_cache.dart
//     - lib/src/ffi/ffi_runtime.dart
//
// Exit codes:
//   0 — all thresholds met.
//   1 — one or more thresholds not met (detailed diff on stderr).
//   2 — couldn't find / parse lcov.info.
//
// Usage:
//   dart run tool/check_coverage.dart [path/to/lcov.info]
//   (default: coverage/lcov.info)

import 'dart:io';

const double _overallThreshold = 80.0;
const double _criticalThreshold = 90.0;

const Set<String> _criticalPaths = {
  'lib/src/backend_io.dart',
  'lib/src/backend_web.dart',
  'lib/src/config.dart',
  'lib/src/ffi/native_bundle_cache.dart',
  'lib/src/ffi/ffi_runtime.dart',
};

class _FileCoverage {
  _FileCoverage(this.path);
  final String path;
  int linesFound = 0;
  int linesHit = 0;
  double get percent => linesFound == 0 ? 100.0 : (linesHit / linesFound) * 100;
}

void main(List<String> args) {
  final lcovPath = args.isEmpty ? 'coverage/lcov.info' : args.first;
  final lcov = File(lcovPath);
  if (!lcov.existsSync()) {
    stderr.writeln('check_coverage: $lcovPath not found. '
        'Run `dart test --coverage=coverage` first.');
    exit(2);
  }

  final files = _parseLcov(lcov.readAsStringSync());
  final libFiles = files.where((f) => f.path.startsWith('lib/')).toList();
  if (libFiles.isEmpty) {
    stderr.writeln('check_coverage: no lib/ files in $lcovPath.');
    exit(2);
  }

  final totalFound = libFiles.fold<int>(0, (sum, f) => sum + f.linesFound);
  final totalHit = libFiles.fold<int>(0, (sum, f) => sum + f.linesHit);
  final overall = totalFound == 0 ? 100.0 : (totalHit / totalFound) * 100;

  stdout.writeln('check_coverage: overall lib/ = '
      '${overall.toStringAsFixed(2)}% (threshold $_overallThreshold%)');

  final failures = <String>[];
  if (overall < _overallThreshold) {
    failures.add('overall: ${overall.toStringAsFixed(2)}% '
        '< $_overallThreshold%');
  }

  for (final critical in _criticalPaths) {
    final hit = libFiles.where((f) => f.path == critical).toList();
    if (hit.isEmpty) {
      failures.add('$critical: no coverage data (expected ≥ '
          '$_criticalThreshold%)');
      continue;
    }
    final pct = hit.first.percent;
    stdout.writeln('check_coverage: $critical = '
        '${pct.toStringAsFixed(2)}% (threshold $_criticalThreshold%)');
    if (pct < _criticalThreshold) {
      failures.add('$critical: ${pct.toStringAsFixed(2)}% '
          '< $_criticalThreshold%');
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('\ncheck_coverage: FAILED');
    for (final f in failures) {
      stderr.writeln('  ✗ $f');
    }
    exit(1);
  }
  stdout.writeln('check_coverage: all thresholds met.');
}

List<_FileCoverage> _parseLcov(String body) {
  final out = <_FileCoverage>[];
  _FileCoverage? current;
  for (final line in body.split('\n')) {
    if (line.startsWith('SF:')) {
      current = _FileCoverage(line.substring(3).trim());
    } else if (line.startsWith('LF:') && current != null) {
      current.linesFound = int.parse(line.substring(3).trim());
    } else if (line.startsWith('LH:') && current != null) {
      current.linesHit = int.parse(line.substring(3).trim());
    } else if (line.trim() == 'end_of_record' && current != null) {
      out.add(current);
      current = null;
    }
  }
  return out;
}
