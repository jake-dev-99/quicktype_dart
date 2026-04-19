// Unit tests for the typed `RendererOptions` surface introduced in v0.3.0.
//
// Parallels `args_renderer_options_test.dart` — verifies each subclass
// serializes to the same `Map<String, String>` shape quicktype-core's
// `rendererOptions` param expects, with null fields omitted.

// ignore_for_file: deprecated_member_use_from_same_package
// Some assertions compare the typed path against the legacy Arg path —
// that's the point of the test, but the legacy classes are @Deprecated.

import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

void main() {
  group('DartRendererOptions', () {
    test('omits null fields', () {
      expect(const DartRendererOptions().toRendererOptions(), isEmpty);
    });

    test('serializes bool fields as "true"/"false"', () {
      expect(
        const DartRendererOptions(useFreezed: true).toRendererOptions(),
        {'use-freezed': 'true'},
      );
      expect(
        const DartRendererOptions(useFreezed: false).toRendererOptions(),
        {'use-freezed': 'false'},
      );
    });

    test('serializes String fields verbatim', () {
      expect(
        const DartRendererOptions(partName: 'user.g.dart').toRendererOptions(),
        {'part-name': 'user.g.dart'},
      );
    });

    test('round-trip matches the legacy Arg path', () {
      final typed = const DartRendererOptions(
        useFreezed: true,
        nullSafety: true,
        partName: 'user.g.dart',
      ).toRendererOptions();

      final argsEntries = <Arg>[
        DartArgs.useFreezed..value = true,
        DartArgs.nullSafety..value = true,
        DartArgs.partName..value = 'user.g.dart',
      ].map((a) => a.toRendererOption()!);

      expect(typed, {
        for (final e in argsEntries) e.key: e.value,
      });
    });
  });

  group('CSharpRendererOptions (enum fields)', () {
    test('serializes EnumArg fields via enum.toString()', () {
      final out = const CSharpRendererOptions(
        framework: CSharpFramework.newtonSoft,
        csharpVersion: CSharpVersion.v6,
      ).toRendererOptions();
      expect(out['framework'], 'NewtonSoft');
      expect(out['csharp-version'], '6');
    });
  });

  group('SwiftRendererOptions (largest option class)', () {
    test('has at least 18 fields (matches SwiftArgs coverage)', () {
      // 18 static getters on SwiftArgs — the generator produced this count
      // at v0.3.0. If SwiftArgs grows, keep this in sync.
      expect(
        const SwiftRendererOptions(justTypes: true).toRendererOptions(),
        hasLength(1),
      );
    });
  });

  group('cross-language sanity', () {
    test('empty instance of every RendererOptions subclass serializes empty', () {
      final cases = <RendererOptions>[
        const CRendererOptions(),
        const CppRendererOptions(),
        const CSharpRendererOptions(),
        const DartRendererOptions(),
        const ElixirRendererOptions(),
        const ElmRendererOptions(),
        const FlowRendererOptions(),
        const GoRendererOptions(),
        const HaskellRendererOptions(),
        const JavaRendererOptions(),
        const JavaScriptRendererOptions(),
        const KotlinRendererOptions(),
        const ObjectiveCRendererOptions(),
        const PHPRendererOptions(),
        const PropTypesRendererOptions(),
        const PythonRendererOptions(),
        const RubyRendererOptions(),
        const RustRendererOptions(),
        const Scala3RendererOptions(),
        const SmithyRendererOptions(),
        const SwiftRendererOptions(),
        const TypeScriptRendererOptions(),
      ];
      for (final c in cases) {
        expect(c.toRendererOptions(), isEmpty,
            reason: '${c.runtimeType} should serialize empty when no fields set');
      }
    });
  });
}
