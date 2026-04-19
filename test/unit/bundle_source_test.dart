// Unit tests for the [BundleSource] abstraction introduced in v0.3.0.

import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BundleSource', () {
    test('embedded is const and reusable', () {
      const a = BundleSource.embedded();
      const b = BundleSource.embedded();
      expect(identical(a, b), isTrue,
          reason:
              'const factory of BundleSource.embedded() should canonicalize');
      expect(a, isA<EmbeddedBundleSource>());
    });

    test('remote captures url + optional integrity', () {
      final src = BundleSource.remote(
        Uri.parse('https://cdn.example.com/quicktype_bundle.js'),
        integrity: 'sha384-abc',
      );
      expect(src, isA<RemoteBundleSource>());
      final r = src as RemoteBundleSource;
      expect(r.url.toString(), 'https://cdn.example.com/quicktype_bundle.js');
      expect(r.integrity, 'sha384-abc');
    });

    test('remote without integrity is valid', () {
      final src = BundleSource.remote(Uri.parse('https://example.com/b.js'));
      expect((src as RemoteBundleSource).integrity, isNull);
    });
  });

  group('QuicktypeDart.setBundleSource', () {
    tearDown(() {
      // Restore default so other tests aren't affected.
      QuicktypeDart.setBundleSource(const BundleSource.embedded());
    });

    test('default is embedded', () {
      expect(QuicktypeDart.bundleSource, isA<EmbeddedBundleSource>());
    });

    test('round-trips a remote source', () {
      final src = BundleSource.remote(Uri.parse('https://example.com/b.js'));
      QuicktypeDart.setBundleSource(src);
      expect(QuicktypeDart.bundleSource, same(src));
    });
  });
}
