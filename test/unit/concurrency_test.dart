@Tags(['slow'])
library;

import 'dart:async';
import 'dart:io';

import 'package:quicktype_dart/src/ffi/native_bundle_cache.dart';
import 'package:test/test.dart';

/// Stress tests guarding the concurrency fixes from Batch A:
///
///   * Atomic cache writes via `tmp + rename`.
///   * Shared runtime init serialized through a `Completer`.
///
/// Tagged `slow` so they run in CI but not on every local loop.
void main() {
  group('native bundle cache under concurrent pressure', () {
    late Directory sandbox;
    late File bundle;
    const body = 'globalThis.qtConvert = () => "stress";';

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('qt_stress_');
      bundle = File('${sandbox.path}/bundle.js')..writeAsStringSync(body);
    });

    tearDown(() {
      sandbox.deleteSync(recursive: true);
    });

    test('64 parallel fetches of the same URL all return identical contents',
        () async {
      final futures = List.generate(
        64,
        (_) => fetchAndCacheBundle(Uri.file(bundle.path), null),
      );
      final results = await Future.wait(futures);
      expect(results, everyElement(equals(body)));
    });

    test('parallel fetches of distinct URLs do not cross-contaminate',
        () async {
      final bundleB = File('${sandbox.path}/bundle_b.js')
        ..writeAsStringSync('globalThis.qtConvert = () => "b";');
      final aFutures = List.generate(
        32,
        (_) => fetchAndCacheBundle(Uri.file(bundle.path), null),
      );
      final bFutures = List.generate(
        32,
        (_) => fetchAndCacheBundle(Uri.file(bundleB.path), null),
      );
      final all = await Future.wait([...aFutures, ...bFutures]);
      final aSlice = all.sublist(0, 32);
      final bSlice = all.sublist(32);
      expect(aSlice, everyElement(equals(body)));
      expect(bSlice, everyElement(equals('globalThis.qtConvert = () => "b";')));
    });
  });
}
