import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:quicktype_dart/src/ffi/native_bundle_cache.dart';
import 'package:quicktype_dart/src/quicktype.dart';
import 'package:test/test.dart';

/// These tests exercise [fetchAndCacheBundle] via file:// URLs — the same
/// path real HTTP fetches take once they've landed on disk. HTTP-specific
/// behavior is left for the ffi_remote_smoke.dart end-to-end check; unit
/// tests would need an injectable HttpClient to cover it meaningfully.
void main() {
  group('fetchAndCacheBundle', () {
    late Directory sandbox;
    late File bundleFile;
    const bundleBody = 'globalThis.qtConvert = () => "fake";';

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('qt_cache_test_');
      bundleFile = File('${sandbox.path}/bundle.js')
        ..writeAsStringSync(bundleBody);
    });

    tearDown(() {
      sandbox.deleteSync(recursive: true);
    });

    test('file:// URL without integrity returns the body', () async {
      final out = await fetchAndCacheBundle(Uri.file(bundleFile.path), null);
      expect(out, equals(bundleBody));
    });

    test('accepts a matching sha256 SRI token', () async {
      final hash = crypto.sha256.convert(utf8.encode(bundleBody));
      final sri = 'sha256-${base64.encode(hash.bytes)}';
      final out = await fetchAndCacheBundle(Uri.file(bundleFile.path), sri);
      expect(out, equals(bundleBody));
    });

    test('accepts a matching sha384 SRI token', () async {
      final hash = crypto.sha384.convert(utf8.encode(bundleBody));
      final sri = 'sha384-${base64.encode(hash.bytes)}';
      final out = await fetchAndCacheBundle(Uri.file(bundleFile.path), sri);
      expect(out, equals(bundleBody));
    });

    test('accepts a matching sha512 SRI token', () async {
      final hash = crypto.sha512.convert(utf8.encode(bundleBody));
      final sri = 'sha512-${base64.encode(hash.bytes)}';
      final out = await fetchAndCacheBundle(Uri.file(bundleFile.path), sri);
      expect(out, equals(bundleBody));
    });

    test('rejects a mismatched integrity token', () async {
      const wrong = 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
      await expectLater(
        fetchAndCacheBundle(Uri.file(bundleFile.path), wrong),
        throwsA(isA<QuicktypeException>().having(
            (e) => e.message, 'message', contains('integrity mismatch'))),
      );
    });

    test('rejects a malformed SRI token', () async {
      await expectLater(
        fetchAndCacheBundle(Uri.file(bundleFile.path), 'not-a-real-hash'),
        // Parse failure surfaces as an integrity mismatch rather than a
        // distinct error — caller still sees the safety net.
        throwsA(isA<QuicktypeException>()),
      );
    });

    test('rejects an unsupported hash algorithm', () async {
      await expectLater(
        fetchAndCacheBundle(Uri.file(bundleFile.path), 'md5-abc'),
        throwsA(isA<QuicktypeException>()),
      );
    });
  });
}
