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

    test('argName values are unique enough to route unambiguously', () {
      final argNames = TargetType.values.map((t) => t.argName).toList();
      // javascript ('js') and flow ('flow') both exist, but they're distinct.
      expect(argNames.toSet(), hasLength(argNames.length),
          reason: 'duplicate argName across TargetType values');
    });
  });

  group('TypeConfig.fromJson', () {
    test('parses path and coerces the args map to rendererOptions', () {
      final cfg = TypeConfig.fromJson(TargetType.dart, {
        'path': 'lib/models/',
        'args': {'use-freezed': true, 'null-safety': false, 'part-name': 'user.g.dart'},
      });
      expect(cfg.path, 'lib/models/');
      expect(cfg.rendererOptions, {
        'use-freezed': 'true',
        'null-safety': 'false',
        'part-name': 'user.g.dart',
      });
    });

    test('falls back to defaultPath when path is omitted', () {
      final cfg = TypeConfig.fromJson(TargetType.dart, {});
      expect(cfg.path, isNotEmpty);
      expect(cfg.rendererOptions, isEmpty);
    });

    test('omits null-valued entries', () {
      final cfg = TypeConfig.fromJson(TargetType.dart, {
        'path': 'lib/',
        'args': {'use-freezed': true, 'part-name': null},
      });
      expect(cfg.rendererOptions, {'use-freezed': 'true'});
    });
  });
}
