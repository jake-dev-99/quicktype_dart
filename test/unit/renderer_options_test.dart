// Unit tests for the typed [RendererOptions] surface.
//
// Verifies each subclass serializes to the `Map<String, String>` shape
// quicktype-core's `rendererOptions` parameter expects, with null fields
// omitted.

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

    test('combines multiple field types in a single map', () {
      final out = const DartRendererOptions(
        useFreezed: true,
        nullSafety: true,
        partName: 'user.g.dart',
      ).toRendererOptions();

      expect(out, {
        'use-freezed': 'true',
        'null-safety': 'true',
        'part-name': 'user.g.dart',
      });
    });
  });

  group('CSharpRendererOptions (enum fields)', () {
    test('serializes enum-typed fields via their toString()', () {
      final out = const CSharpRendererOptions(
        framework: CSharpFramework.newtonSoft,
        csharpVersion: CSharpVersion.v6,
      ).toRendererOptions();
      expect(out['framework'], 'NewtonSoft');
      expect(out['csharp-version'], '6');
    });
  });

  group('SwiftRendererOptions', () {
    test('serializes a single bool field as a one-entry map', () {
      expect(
        const SwiftRendererOptions(justTypes: true).toRendererOptions(),
        {'just-types': 'true'},
      );
    });
  });

  group('cross-language sanity', () {
    test('empty instance of every RendererOptions subclass serializes empty',
        () {
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
        const SwiftRendererOptions(),
        const TypeScriptRendererOptions(),
      ];
      for (final c in cases) {
        expect(c.toRendererOptions(), isEmpty,
            reason:
                '${c.runtimeType} should serialize empty when no fields set');
      }
    });
  });
}
