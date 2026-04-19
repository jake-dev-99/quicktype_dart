import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Arg.argv()', () {
    test('SimpleArg emits --name only when value == true', () {
      expect(SimpleArg('help').argv(), isEmpty);
      expect((SimpleArg('help')..value = false).argv(), isEmpty);
      expect((SimpleArg('help')..value = true).argv(), ['--help']);
    });

    test('StringArg emits --name value when set', () {
      expect(StringArg('out').argv(), isEmpty);
      expect((StringArg('out')..value = 'foo.dart').argv(),
          ['--out', 'foo.dart']);
    });

    test('StringArg preserves spaces and quotes in values', () {
      final argv = (StringArg('name')..value = 'has "quotes" and spaces').argv();
      expect(argv, ['--name', 'has "quotes" and spaces']);
      // Each argv element is separate — no shell escaping needed for
      // Process.run.
    });

    test('BoolArg emits --name or --no-name', () {
      expect(BoolArg('null-safety').argv(), isEmpty);
      expect((BoolArg('null-safety')..value = true).argv(), ['--null-safety']);
      expect(
          (BoolArg('null-safety')..value = false).argv(), ['--no-null-safety']);
    });

    test('EnumArg emits --name enum.toString()', () {
      final arg = EnumArg<HttpMethod>('http-method');
      expect(arg.argv(), isEmpty);
      arg.value = HttpMethod.post;
      expect(arg.argv(), ['--http-method', 'post']);
    });

    test('RepeatableArg emits --name value for each entry', () {
      expect(RepeatableArg('header', []).argv(), isEmpty);
      expect(
        RepeatableArg('header', ['a: 1', 'b: 2']).argv(),
        ['--header', 'a: 1', '--header', 'b: 2'],
      );
    });
  });

  group('DartArgs', () {
    test('known flags are in the registry', () {
      final reg = DartArgs.args;
      expect(reg.keys,
          containsAll(['null-safety', 'just-types', 'use-freezed']));
    });

    test('getters produce independent instances (no shared mutable state)', () {
      final a = DartArgs.useFreezed..value = true;
      final b = DartArgs.useFreezed;
      expect(a.value, isTrue);
      expect(b.value, isNull, reason: 'each getter call must return a fresh Arg');
    });
  });
}
