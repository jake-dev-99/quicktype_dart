import 'package:quicktype_dart/src/quicktype.dart';
import 'package:test/test.dart';

void main() {
  group('QuicktypeException', () {
    test('preserves cause and stackTrace', () {
      final inner = FormatException('bad argv');
      final st = StackTrace.current;
      final ex = QuicktypeException(
        'Failed to run quicktype',
        command: 'quicktype --foo',
        cause: inner,
        stackTrace: st,
      );
      expect(ex.cause, same(inner));
      expect(ex.stackTrace, same(st));
      expect(ex.toString(), contains('Caused by: FormatException'));
      expect(ex.toString(), contains('Command: quicktype --foo'));
    });

    test('omits Caused by when no cause supplied', () {
      final ex = QuicktypeException('nope');
      expect(ex.toString(), isNot(contains('Caused by')));
    });
  });
}
