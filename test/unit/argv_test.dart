import 'package:quicktype_dart/src/internal/argv.dart';
import 'package:test/test.dart';

void main() {
  group('rendererOptionsToArgv', () {
    test('empty map produces empty argv', () {
      expect(rendererOptionsToArgv(const {}), isEmpty);
    });

    test('"true" collapses to --flag (no value)', () {
      expect(
        rendererOptionsToArgv(const {'just-types': 'true'}),
        equals(['--just-types']),
      );
    });

    test('"false" collapses to --no-flag (no value)', () {
      expect(
        rendererOptionsToArgv(const {'just-types': 'false'}),
        equals(['--no-just-types']),
      );
    });

    test('other strings become --flag value', () {
      expect(
        rendererOptionsToArgv(const {'part-name': 'user.g.dart'}),
        equals(['--part-name', 'user.g.dart']),
      );
    });

    test('mixed shapes preserve map iteration order', () {
      expect(
        rendererOptionsToArgv(const {
          'use-freezed': 'true',
          'null-safety': 'false',
          'part-name': 'user.g.dart',
        }),
        equals([
          '--use-freezed',
          '--no-null-safety',
          '--part-name',
          'user.g.dart',
        ]),
      );
    });

    test('value strings that look like bool flags are passed through verbatim',
        () {
      // 'True' (capital) is NOT the bool canonical form — treat as value.
      expect(
        rendererOptionsToArgv(const {'framework': 'True'}),
        equals(['--framework', 'True']),
      );
    });
  });
}
