import 'package:path/path.dart' as p;
import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

void main() {
  group('QuicktypeCommand.argv', () {
    test('emits canonical --src/--src-lang/--lang/--out', () {
      final cmd = QuicktypeCommand(
        sourcePath: 'models/user.json',
        sourceArg: 'json',
        targetPath: 'lib/user.dart',
        targetArg: 'dart',
      );
      final argv = cmd.argv;
      expect(argv, contains('--src'));
      expect(argv, contains('--src-lang'));
      expect(argv, contains('json'));
      expect(argv, contains('--lang'));
      expect(argv, contains('dart'));
      expect(argv, contains('--out'));
      // Paths are canonicalized to absolute.
      expect(argv[argv.indexOf('--src') + 1], p.canonicalize('models/user.json'));
      expect(argv[argv.indexOf('--out') + 1], p.canonicalize('lib/user.dart'));
    });

    test('appends extra Arg instances after the core flags', () {
      final cmd = QuicktypeCommand(
        sourcePath: 'in.json',
        sourceArg: 'json',
        targetPath: 'out.dart',
        targetArg: 'dart',
        args: [DartArgs.useFreezed..value = true],
      );
      expect(cmd.argv, contains('--use-freezed'));
    });

    test('empty args produces just the core flags', () {
      final cmd = QuicktypeCommand(
        sourcePath: 'in.json',
        sourceArg: 'json',
        targetPath: 'out.dart',
        targetArg: 'dart',
      );
      // 4 core flags × 2 tokens = 8 elements.
      expect(cmd.argv, hasLength(8));
    });
  });
}
