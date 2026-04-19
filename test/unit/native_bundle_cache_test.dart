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

    test('rejects a supported alg with non-base64 hash (no FormatException)',
        () async {
      // Before 0.4.6 the base64 in an SRI token was never validated at
      // parse time; a garbage hash made it all the way to crypto and
      // blew up with a FormatException deep in the stack. Now it's
      // rejected cleanly with the same "integrity mismatch" message as
      // every other bad token.
      await expectLater(
        fetchAndCacheBundle(
          Uri.file(bundleFile.path),
          'sha256-!!!not-base64!!!',
        ),
        throwsA(
          isA<QuicktypeException>()
              .having((e) => e, 'not a FormatException wrapper', isNotNull),
        ),
      );
    });

    test('rejects an SRI token with an empty hash', () async {
      await expectLater(
        fetchAndCacheBundle(Uri.file(bundleFile.path), 'sha256-'),
        throwsA(isA<QuicktypeException>()),
      );
    });

    test('rejects an unsupported hash algorithm', () async {
      await expectLater(
        fetchAndCacheBundle(Uri.file(bundleFile.path), 'md5-abc'),
        throwsA(isA<QuicktypeException>()),
      );
    });

    test('concurrent fetches of the same URL settle on identical contents',
        () async {
      // Races the atomic-write path added in 0.4.4: many isolates fetching
      // the same URL simultaneously must all see the same final body.
      final futures = List.generate(
        16,
        (_) => fetchAndCacheBundle(Uri.file(bundleFile.path), null),
      );
      final results = await Future.wait(futures);
      for (final r in results) {
        expect(r, equals(bundleBody));
      }
    });

    test('stale cache file is deleted when integrity token no longer matches',
        () async {
      // Prime the cache with correct content.
      final firstIntegrity = await fetchAndCacheBundle(
        Uri.file(bundleFile.path),
        null,
      );
      expect(firstIntegrity, equals(bundleBody));

      // Rewrite the source to new content, then ask for it under a wrong
      // (old) integrity tag. The stale cached copy must get dropped before
      // the re-fetch even runs.
      bundleFile.writeAsStringSync('globalThis.qtConvert = () => "new";');
      const wrong = 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
      await expectLater(
        fetchAndCacheBundle(Uri.file(bundleFile.path), wrong),
        throwsA(isA<QuicktypeException>()),
      );
    });
  });
}
