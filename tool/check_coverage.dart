// Parses `coverage/lcov.info` and enforces minimum line-coverage
// thresholds. Invoked from CI after `dart test --coverage` has
// produced the lcov file.
//
// Thresholds are set to the **unit-test-only baseline** this package
// can reach today. Modules that need real quicktype / a browser / the
// native FFI lib to exercise (backend_io, backend_web, ffi_runtime)
// sit below 90% until CI merges unit + integration + browser coverage
// into one lcov file. Tracked for Batch I.
//
// Current gates:
//   * Overall lib/ line coverage  ≥ 45%
//   * Critical-path files         as listed in [_criticalThresholds]
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

const double _overallThreshold = 45.0;

/// Per-file minimum line coverage. Raise entries as tests come in.
/// Keeping explicit per-file numbers (instead of one critical-path
/// bar) lets us ratchet each module independently — a regression on
/// an already-tested file is still caught, but modules that only
/// integration tests can exercise aren't held to a bar that unit
/// tests can't move.
const Map<String, double> _criticalThresholds = {
  'lib/src/config.dart': 90.0,
  'lib/src/ffi/native_bundle_cache.dart': 70.0,
  // Gated at 0 so the file shows up in the report without failing
  // the job — CI merges unit + integration coverage in Batch I, at
  // which point these can move up toward 90.
  'lib/src/backend_io.dart': 0.0,
  'lib/src/backend_web.dart': 0.0,
  'lib/src/ffi/ffi_runtime.dart': 0.0,
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

  // Normalize every SF: entry to a repo-root-relative path so the
  // thresholds table can match by `lib/src/…` regardless of whether
  // the coverage tool emitted absolute or relative paths.
  final files = _parseLcov(lcov.readAsStringSync())
      .map((f) => _FileCoverage(_normalizePath(f.path))
        ..linesFound = f.linesFound
        ..linesHit = f.linesHit)
      .toList();
  final libFiles = files.where((f) => f.path.startsWith('lib/')).toList();
  if (libFiles.isEmpty) {
    stderr.writeln('check_coverage: no lib/ files in $lcovPath.');
    stderr.writeln('First 5 raw SF: entries:');
    for (final f in files.take(5)) {
      stderr.writeln('  ${f.path}');
    }
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

  for (final entry in _criticalThresholds.entries) {
    final critical = entry.key;
    final threshold = entry.value;
    final hit = libFiles.where((f) => f.path == critical).toList();
    if (hit.isEmpty) {
      if (threshold > 0) {
        failures.add('$critical: no coverage data (expected ≥ $threshold%)');
      } else {
        stdout.writeln('check_coverage: $critical = (no data, gate disabled)');
      }
      continue;
    }
    final pct = hit.first.percent;
    stdout.writeln('check_coverage: $critical = '
        '${pct.toStringAsFixed(2)}% (threshold $threshold%)');
    if (pct < threshold) {
      failures.add('$critical: ${pct.toStringAsFixed(2)}% < $threshold%');
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

/// Trims an `SF:` entry down to a `lib/…` or `test/…` path relative
/// to the repo root. Accepts absolute paths (which is what
/// `coverage:test_with_coverage` emits by default) and already-relative
/// paths.
String _normalizePath(String raw) {
  if (raw.startsWith('lib/') || raw.startsWith('test/')) return raw;
  const markers = ['/lib/', '/test/'];
  for (final m in markers) {
    final idx = raw.indexOf(m);
    if (idx >= 0) return raw.substring(idx + 1);
  }
  return raw;
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
