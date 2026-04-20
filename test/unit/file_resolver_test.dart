import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quicktype_dart/src/config.dart';
import 'package:quicktype_dart/src/models/type.dart';
import 'package:quicktype_dart/src/file_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('FileResolver.getFiles', () {
    late Directory sandbox;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('qt_fileresolver_');
    });

    tearDown(() {
      sandbox.deleteSync(recursive: true);
    });

    File touch(String rel, [String body = '{}']) =>
        File(p.join(sandbox.path, rel))
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(body);

    test('returns matching files under a directory (single extension)', () {
      touch('a.json');
      touch('b.json');
      touch('c.txt');
      final matches = FileResolver.getFiles(sandbox.path, {'.json'});
      expect(matches.length, 2);
      expect(matches.every((m) => m.endsWith('.json')), isTrue);
    });

    test('multi-extension brace expansion matches every listed extension', () {
      touch('schema.graphql', 'type A { a: Int }');
      touch('other.graphqls', 'type B { b: Int }');
      touch('skip.txt', 'nope');
      final matches = FileResolver.getFiles(
        sandbox.path,
        {'.graphql', '.graphqls'},
      );
      expect(matches.length, 2);
      expect(
        matches.map(p.basename).toSet(),
        {'schema.graphql', 'other.graphqls'},
      );
    });

    test('matches multi-dot extensions (.schema.json) without collapsing', () {
      touch('user.schema.json');
      touch('other.json');
      final matches =
          FileResolver.getFiles(sandbox.path, {'.schema.json'});
      expect(matches.length, 1);
      expect(matches.single, endsWith('user.schema.json'));
    });

    test('accepts a pattern that points directly at a file', () {
      final f = touch('direct.json');
      final matches = FileResolver.getFiles(f.path, {'.json'});
      expect(matches.single, f.absolute.path);
    });

    test('rejects a pattern whose extension is not in the allowed set', () {
      expect(
        () => FileResolver.getFiles('models/file.xml', {'.json'}),
        throwsA(isA<ConfigException>().having(
          (e) => e.message,
          'message',
          contains('.xml'),
        )),
      );
    });

    test('rejects an empty extension set', () {
      expect(
        () => FileResolver.getFiles(sandbox.path, <String>{}),
        throwsA(isA<ConfigException>()),
      );
    });

    test('returns an empty set when the directory has no matches', () {
      touch('a.txt');
      final matches = FileResolver.getFiles(sandbox.path, {'.json'});
      expect(matches, isEmpty);
    });

    test('trailing slash vs no trailing slash both resolve the directory',
        () {
      touch('a.json');
      final withSlash = FileResolver.getFiles('${sandbox.path}/', {'.json'});
      final without = FileResolver.getFiles(sandbox.path, {'.json'});
      expect(withSlash, without);
    });

    test('pre-existing trailing wildcard is preserved (no double /*)', () {
      touch('a.json');
      touch('b.json');
      final matches =
          FileResolver.getFiles('${sandbox.path}/*', {'.json'});
      expect(matches.length, 2);
    });
  });

  group('FileResolver.resolveTargetPath', () {
    test('joins the source stem and target extension under a directory', () {
      const cfg = TypeConfig(type: TargetType.dart, path: 'lib/models/');
      final out = FileResolver.resolveTargetPath(
        '/tmp/user.json',
        TargetType.dart,
        cfg,
      );
      expect(out, p.join('lib/models/', 'user.dart'));
    });

    test('uses the parent of a file-shaped target path', () {
      const cfg = TypeConfig(type: TargetType.dart, path: 'lib/models/x.dart');
      final out = FileResolver.resolveTargetPath(
        '/tmp/user.json',
        TargetType.dart,
        cfg,
      );
      expect(p.dirname(out), 'lib/models');
      expect(p.basename(out), 'user.dart');
    });

    test('multi-dot source extensions strip only the last segment', () {
      // Behavior note: `user.schema.json` yields `user.schema.dart`. Users
      // who want cleaner names should pre-strip or rename the source.
      const cfg = TypeConfig(type: TargetType.dart, path: 'lib/models/');
      final out = FileResolver.resolveTargetPath(
        '/tmp/user.schema.json',
        TargetType.dart,
        cfg,
      );
      expect(p.basename(out), 'user.schema.dart');
    });
  });
}
