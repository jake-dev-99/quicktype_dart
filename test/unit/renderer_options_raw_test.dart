// Coverage for the escape-hatch RendererOptions.raw factory, used by the
// build_runner builder to tunnel a pre-coerced Map through the typed
// `options:` parameter on QuicktypeDart.generateFromString.

import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

void main() {
  group('RendererOptions.raw', () {
    test('round-trips an arbitrary Map verbatim', () {
      const r = RendererOptions.raw({
        'just-types': 'true',
        'part-name': 'user.g.dart',
      });
      expect(r.toRendererOptions(), {
        'just-types': 'true',
        'part-name': 'user.g.dart',
      });
    });

    test('an empty map stays empty', () {
      const r = RendererOptions.raw({});
      expect(r.toRendererOptions(), isEmpty);
    });

    test('is const-constructible', () {
      const a = RendererOptions.raw({});
      const b = RendererOptions.raw({});
      expect(identical(a, b), isTrue);
    });
  });
}
