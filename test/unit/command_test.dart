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
      expect(
          argv[argv.indexOf('--src') + 1], p.canonicalize('models/user.json'));
      expect(argv[argv.indexOf('--out') + 1], p.canonicalize('lib/user.dart'));
    });

    test('appends true-valued renderer options as --flag after the core flags',
        () {
      final cmd = QuicktypeCommand(
        sourcePath: 'in.json',
        sourceArg: 'json',
        targetPath: 'out.dart',
        targetArg: 'dart',
        rendererOptions: const {'use-freezed': 'true'},
      );
      expect(cmd.argv, contains('--use-freezed'));
    });

    test('collapses false-valued renderer options to --no-flag', () {
      final cmd = QuicktypeCommand(
        sourcePath: 'in.json',
        sourceArg: 'json',
        targetPath: 'out.dart',
        targetArg: 'dart',
        rendererOptions: const {'null-safety': 'false'},
      );
      expect(cmd.argv, contains('--no-null-safety'));
    });

    test('passes string-valued renderer options as --flag value', () {
      final cmd = QuicktypeCommand(
        sourcePath: 'in.json',
        sourceArg: 'json',
        targetPath: 'out.dart',
        targetArg: 'dart',
        rendererOptions: const {'part-name': 'user.g.dart'},
      );
      final argv = cmd.argv;
      final i = argv.indexOf('--part-name');
      expect(i, greaterThanOrEqualTo(0));
      expect(argv[i + 1], 'user.g.dart');
    });

    test('empty rendererOptions produces just the core flags', () {
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
