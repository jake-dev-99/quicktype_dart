import 'package:quicktype_dart/src/utils/shell.dart';
import 'package:test/test.dart';

void main() {
  group('shellQuote', () {
    test('leaves plain alphanumeric arguments unquoted', () {
      expect(shellQuote('foo'), equals('foo'));
      expect(shellQuote('foo-bar'), equals('foo-bar'));
      expect(shellQuote('/tmp/out.dart'), equals('/tmp/out.dart'));
      expect(shellQuote('--lang=dart'), equals('--lang=dart'));
    });

    test('single-quotes arguments containing whitespace', () {
      expect(shellQuote('foo bar'), equals("'foo bar'"));
      expect(
          shellQuote('/tmp/has space/file'), equals("'/tmp/has space/file'"));
    });

    test('escapes embedded single quotes', () {
      expect(shellQuote("it's"), equals(r"'it'\''s'"));
    });

    test('empty string becomes explicit empty quotes', () {
      expect(shellQuote(''), equals("''"));
    });

    test('quotes arguments with shell-special characters', () {
      expect(shellQuote(r'foo$bar'), equals(r"'foo$bar'"));
      expect(shellQuote('a;b'), equals("'a;b'"));
      expect(shellQuote('*.dart'), equals("'*.dart'"));
    });
  });

  group('formatCommand', () {
    test('joins exe and argv with single spaces', () {
      expect(
        formatCommand('/usr/bin/quicktype', ['--lang', 'dart']),
        equals('/usr/bin/quicktype --lang dart'),
      );
    });

    test('quotes only the parts that need it', () {
      expect(
        formatCommand('/usr/bin/quicktype', [
          '--out',
          '/tmp/has space/user.dart',
          '--lang',
          'dart',
        ]),
        equals(
            "/usr/bin/quicktype --out '/tmp/has space/user.dart' --lang dart"),
      );
    });
  });
}
