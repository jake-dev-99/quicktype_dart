import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quicktype_dart/src/internal/temp_dir_sweeper.dart';
import 'package:test/test.dart';

void main() {
  group('TempDirSweeper', () {
    late Directory sandbox;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('qt_sweeper_test_');
    });

    tearDown(() {
      if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
    });

    Directory makeTempChild(String name) {
      final d = Directory(p.join(sandbox.path, name))
        ..createSync(recursive: true);
      File(p.join(d.path, 'marker.txt')).writeAsStringSync('x');
      return d;
    }

    test('cleanup deletes an existing directory', () {
      final sweeper = TempDirSweeper();
      final d = makeTempChild('a');
      expect(d.existsSync(), isTrue);
      sweeper.cleanup(d);
      expect(d.existsSync(), isFalse);
      expect(sweeper.deferredCount, 0);
    });

    test('cleanup is tolerant of an already-missing directory', () {
      final sweeper = TempDirSweeper();
      final ghost = Directory(p.join(sandbox.path, 'never-existed'));
      sweeper.cleanup(ghost);
      expect(sweeper.deferredCount, 0);
    });

    test('multiple cleanups on distinct dirs leave no leftovers', () {
      final sweeper = TempDirSweeper();
      final a = makeTempChild('a');
      final b = makeTempChild('b');
      sweeper.cleanup(a);
      sweeper.cleanup(b);
      expect(a.existsSync(), isFalse);
      expect(b.existsSync(), isFalse);
      expect(sweeper.deferredCount, 0);
    });
  });
}
