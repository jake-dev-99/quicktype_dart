import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TargetType', () {
    test('every value has a non-empty extension set', () {
      for (final t in TargetType.values) {
        expect(t.extensions, isNotEmpty, reason: '${t.name} has no extensions');
      }
    });

    test('every value has a non-empty argName', () {
      for (final t in TargetType.values) {
        expect(t.argName, isNotEmpty, reason: '${t.name} has no argName');
      }
    });

    test('args registry resolves for every value', () {
      for (final t in TargetType.values) {
        expect(() => t.args, returnsNormally,
            reason: '${t.name}.args throws');
      }
    });

    test('argName values are unique enough to route unambiguously', () {
      final argNames = TargetType.values.map((t) => t.argName).toList();
      // javascript ('js') and flow ('flow') both exist, but they're distinct.
      expect(argNames.toSet(), hasLength(argNames.length),
          reason: 'duplicate argName across TargetType values');
    });
  });

  group('TypeConfig.fromJson', () {
    test('parses path and args', () {
      final cfg = TypeConfig.fromJson(TargetType.dart, {
        'path': 'lib/models/',
        'args': {'use-freezed': true, 'null-safety': true},
      });
      expect(cfg.path, 'lib/models/');
      expect(cfg.args, hasLength(2));
      expect(cfg.args.map((a) => a.name),
          containsAll(['use-freezed', 'null-safety']));
    });

    test('falls back to defaultPath when path is omitted', () {
      final cfg = TypeConfig.fromJson(TargetType.dart, {});
      expect(cfg.path, isNotEmpty);
    });

    test('silently skips unknown arg keys (logs warning)', () {
      final cfg = TypeConfig.fromJson(TargetType.dart, {
        'path': 'lib/',
        'args': {'totally-made-up-flag': true, 'use-freezed': true},
      });
      expect(cfg.args, hasLength(1));
      expect(cfg.args.first.name, 'use-freezed');
    });
  });
}
