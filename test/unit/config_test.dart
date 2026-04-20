import 'dart:io';

import 'package:quicktype_dart/src/config.dart';
import 'package:quicktype_dart/src/models/type.dart';
import 'package:test/test.dart';

/// Covers the shape-validation paths and the loader fallbacks after the
/// 0.5.0 de-singleton refactor. `Config` is now a plain value class —
/// every test constructs its own instance; there is no shared state to
/// reset between cases.

/// Registers per-test setUp/tearDown that creates and deletes a temp dir.
/// Returns a thunk that resolves to the current sandbox from inside a
/// test body.
Directory Function() _sandboxPerTest(String prefix) {
  late Directory sandbox;
  setUp(() {
    sandbox = Directory.systemTemp.createTempSync(prefix);
  });
  tearDown(() {
    sandbox.deleteSync(recursive: true);
  });
  return () => sandbox;
}

void main() {
  group('Config.fromFile', () {
    final sandbox = _sandboxPerTest('qt_config_test_');

    test('throws when the file is missing', () {
      expect(
        () => Config.fromFile('${sandbox().path}/missing.json'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws on a non-object root', () {
      final f = File('${sandbox().path}/bad.json')..writeAsStringSync('[]');
      expect(
        () => Config.fromFile(f.path),
        throwsA(isA<ConfigException>().having(
          (e) => e.message,
          'message',
          contains('must be a JSON object'),
        )),
      );
    });

    test('throws on unparseable JSON', () {
      final f = File('${sandbox().path}/bad.json')..writeAsStringSync('{not');
      expect(() => Config.fromFile(f.path), throwsA(isA<ConfigException>()));
    });

    test('throws when sources is the wrong shape', () {
      final f = File('${sandbox().path}/bad.json')
        ..writeAsStringSync('{"sources": "oops"}');
      expect(
        () => Config.fromFile(f.path),
        throwsA(isA<ConfigException>().having(
          (e) => e.message,
          'message',
          contains('"sources"'),
        )),
      );
    });

    test('throws when a target value is not a list', () {
      final f = File('${sandbox().path}/bad.json')
        ..writeAsStringSync('{"targets": {"dart": "oops"}}');
      expect(
        () => Config.fromFile(f.path),
        throwsA(isA<ConfigException>().having(
          (e) => e.message,
          'message',
          contains('must be a list'),
        )),
      );
    });

    test('valid config loads without falling back', () {
      final f = File('${sandbox().path}/q.json')
        ..writeAsStringSync(
          '{"sources": {"json": [{"path": "models"}]}, "targets": {}}',
        );
      final cfg = Config.fromFile(f.path);
      expect(cfg.sources, isNotEmpty);
    });
  });

  group('Config.fromMap', () {
    test('round-trips a minimal map', () {
      final cfg = Config.fromMap(<String, dynamic>{
        'sources': <String, dynamic>{
          'json': [
            <String, dynamic>{'path': 'models/'},
          ],
        },
        'targets': <String, dynamic>{},
      });
      expect(cfg.sources, contains(SourceType.json));
    });
  });

  group('Config.loadOrDefaults', () {
    final sandbox = _sandboxPerTest('qt_config_default_');

    test('returns defaults when the file is missing', () {
      final cfg = Config.loadOrDefaults(path: '${sandbox().path}/missing.json');
      expect(cfg.sources, isNotEmpty);
    });

    test('returns defaults when the file is malformed', () {
      final f = File('${sandbox().path}/bad.json')..writeAsStringSync('[]');
      final cfg = Config.loadOrDefaults(path: f.path);
      expect(cfg.sources, isNotEmpty);
    });

    test('independent instances do not share state', () {
      final a = Config.fromMap(<String, dynamic>{
        'sources': <String, dynamic>{},
        'targets': <String, dynamic>{},
      });
      final b = Config.defaults();
      expect(identical(a.sources, b.sources), isFalse);
    });
  });
}
