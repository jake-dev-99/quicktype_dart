import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quicktype_dart/src/internal/package_layout.dart';
import 'package:test/test.dart';

void main() {
  group('packageRoot', () {
    test('resolves to a directory containing pubspec.yaml', () async {
      final root = await packageRoot();
      expect(root, isNotNull,
          reason: 'Isolate.resolvePackageUri should resolve during tests');
      expect(
        File(p.join(root!, 'pubspec.yaml')).existsSync(),
        isTrue,
        reason: 'packageRoot() must point at the dir containing pubspec.yaml',
      );
    });
  });

  group('bundledQuicktypeExe', () {
    test('returns null when the bundled CLI is absent, else a File on disk',
        () async {
      final exe = await bundledQuicktypeExe();
      if (exe == null) {
        // Acceptable on fresh clones where `npm install` hasn't run.
        return;
      }
      expect(exe, endsWith(bundledQuicktypeExeRelative));
      expect(File(exe).existsSync(), isTrue);
    });
  });
}
