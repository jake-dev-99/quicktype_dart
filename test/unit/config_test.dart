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

    test('strict: true rethrows ConfigException on a malformed file', () {
      final f = File('${sandbox().path}/bad.json')..writeAsStringSync('[]');
      expect(
        () => Config.loadOrDefaults(path: f.path, strict: true),
        throwsA(isA<ConfigException>()),
      );
    });

    test('strict: true still falls back when the file is missing', () {
      final cfg = Config.loadOrDefaults(
        path: '${sandbox().path}/missing.json',
        strict: true,
      );
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

    test('Config.defaults() creates models/ when absent', () {
      final prev = Directory.current;
      try {
        Directory.current = sandbox();
        expect(Directory('models').existsSync(), isFalse);
        final cfg = Config.defaults();
        expect(Directory('models').existsSync(), isTrue);
        expect(cfg.sources, isNotEmpty);
      } finally {
        Directory.current = prev;
      }
    });
  });

  group('ConfigException.toString', () {
    test('omits "Caused by" when no cause was attached', () {
      const e = ConfigException('bad config');
      expect(e.toString(), 'ConfigException: bad config');
    });

    test('includes "Caused by" when a cause is present', () {
      const cause = FormatException('bad json');
      final e = ConfigException('wrap me', cause);
      expect(e.toString(), contains('ConfigException: wrap me'));
      expect(e.toString(), contains('Caused by: FormatException'));
    });
  });

  group('Config.fromMap shape errors', () {
    test('throws when a target key is not a recognized language', () {
      expect(
        () => Config.fromMap(<String, dynamic>{
          'sources': <String, dynamic>{},
          'targets': <String, dynamic>{'wat': <dynamic>[]},
        }),
        throwsA(isA<ConfigException>().having(
          (e) => e.message,
          'message',
          contains('Unknown target'),
        )),
      );
    });

    test('throws when a list entry is not an object', () {
      expect(
        () => Config.fromMap(<String, dynamic>{
          'sources': <String, dynamic>{
            'json': <dynamic>['nope'],
          },
          'targets': <String, dynamic>{},
        }),
        throwsA(isA<ConfigException>().having(
          (e) => e.message,
          'message',
          contains('entries must be objects'),
        )),
      );
    });

    test('missing targets key falls back to defaults', () {
      final cfg = Config.fromMap(<String, dynamic>{
        'sources': <String, dynamic>{
          'json': [
            <String, dynamic>{'path': 'models/'},
          ],
        },
      });
      expect(cfg.targets, isNotEmpty);
    });

    test('missing sources key falls back to defaults', () {
      final cfg = Config.fromMap(<String, dynamic>{
        'targets': <String, dynamic>{},
      });
      expect(cfg.sources, isNotEmpty);
    });

    test('argName alias resolves alongside the enum name', () {
      // TargetType.csharp has argName 'cs'; both must route to the
      // same enum via _findTypeByKey.
      final byName = Config.fromMap(<String, dynamic>{
        'sources': <String, dynamic>{},
        'targets': <String, dynamic>{
          'csharp': [
            <String, dynamic>{'path': 'out'},
          ],
        },
      });
      final byArg = Config.fromMap(<String, dynamic>{
        'sources': <String, dynamic>{},
        'targets': <String, dynamic>{
          'cs': [
            <String, dynamic>{'path': 'out'},
          ],
        },
      });
      expect(byName.targets.keys.single, TargetType.csharp);
      expect(byArg.targets.keys.single, TargetType.csharp);
    });
  });
}
