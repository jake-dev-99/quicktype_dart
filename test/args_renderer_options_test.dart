import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

/// Covers `Arg.toRendererOption()` — the FFI transport's arg-serialization
/// path. Each subclass maps `null` → skip; non-null → a `(name, stringified)`
/// entry usable as a quicktype-core `rendererOptions` key/value pair.
void main() {
  group('Arg.toRendererOption()', () {
    test('SimpleArg emits {name: "true"} only when value == true', () {
      expect(SimpleArg('help').toRendererOption(), isNull);
      expect((SimpleArg('help')..value = false).toRendererOption(), isNull);
      final entry = (SimpleArg('help')..value = true).toRendererOption();
      expect(entry, isNotNull);
      expect(entry!.key, 'help');
      expect(entry.value, 'true');
    });

    test('StringArg emits {name: value} when set', () {
      expect(StringArg('out').toRendererOption(), isNull);
      final entry =
          (StringArg('out')..value = 'foo.dart').toRendererOption();
      expect(entry, isNotNull);
      expect(entry!.key, 'out');
      expect(entry.value, 'foo.dart');
    });

    test('BoolArg emits "true" or "false"', () {
      expect(BoolArg('null-safety').toRendererOption(), isNull);
      final t =
          (BoolArg('null-safety')..value = true).toRendererOption();
      expect(t!.value, 'true');
      final f =
          (BoolArg('null-safety')..value = false).toRendererOption();
      expect(f!.value, 'false');
    });

    test('EnumArg emits enum.toString()', () {
      final arg = EnumArg<HttpMethod>('http-method');
      expect(arg.toRendererOption(), isNull);
      arg.value = HttpMethod.post;
      final entry = arg.toRendererOption();
      expect(entry!.key, 'http-method');
      expect(entry.value, 'post');
    });

    test('RepeatableArg joins values with commas', () {
      expect(RepeatableArg('header', []).toRendererOption(), isNull);
      final entry =
          RepeatableArg('header', ['a: 1', 'b: 2']).toRendererOption();
      expect(entry!.value, 'a: 1,b: 2');
    });
  });
}
