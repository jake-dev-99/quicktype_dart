// Golden-file tests for the public `QuicktypeDart.generate` surface,
// covering each primary consumer target language so a quicktype-core
// upgrade or renderer-option change can't silently regress output.
//
// Layout:
//   test/integration/goldens/user_sample.input.json   — shared payload
//   test/integration/goldens/<case>.<ext>.txt         — expected output
//     where <case> is the `name` on `_Case` and <ext> is
//     `target.extensions.first.substring(1)`.
//
// To update every golden after an intentional output change, re-run
// with the `GOLDEN=update` environment variable:
//
//     GOLDEN=update dart test test/integration/golden_test.dart \
//       --tags=integration
//
// Any quicktype-core upgrade or renderer-option change that affects
// output has to land with a matching golden update in the same PR.
//
// Coverage spans every TargetType value so a quicktype-core upgrade is
// immediately visible across the full language matrix, not just the
// primary consumer subset.

@Tags(['integration'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

const _goldenDir = 'test/integration/goldens';
const _sharedInput = 'user_sample';

class _Case {
  const _Case(this.name, this.target, this.options);

  /// Short identifier used as the golden filename stem.
  final String name;

  /// Target language.
  final TargetType target;

  /// Language-specific renderer options. `null` = quicktype-core
  /// defaults. Targets that expose `justTypes` use it to produce
  /// leaner, more review-friendly goldens.
  final RendererOptions? options;
}

void main() {
  // Cases intentionally use `justTypes: true` where available so the
  // goldens focus on type-shape regressions (not serializer
  // boilerplate). Languages without a `justTypes` option fall back to
  // the quicktype-core default shape.
  final cases = <_Case>[
    const _Case(
      'user_dart_just_types',
      TargetType.dart,
      DartRendererOptions(justTypes: true),
    ),
    const _Case('user_kotlin', TargetType.kotlin, null),
    const _Case(
      'user_swift_just_types',
      TargetType.swift,
      SwiftRendererOptions(justTypes: true),
    ),
    const _Case(
      'user_typescript_just_types',
      TargetType.typescript,
      TypeScriptRendererOptions(justTypes: true),
    ),
    const _Case('user_csharp', TargetType.csharp, null),
    const _Case(
      'user_python_just_types',
      TargetType.python,
      PythonRendererOptions(justTypes: true),
    ),
    const _Case(
      'user_java_just_types',
      TargetType.java,
      JavaRendererOptions(justTypes: true),
    ),
    const _Case(
      'user_go_just_types',
      TargetType.go,
      GoRendererOptions(justTypes: true),
    ),
    const _Case('user_rust', TargetType.rust, null),
    const _Case(
      'user_cpp_just_types',
      TargetType.cpp,
      CppRendererOptions(justTypes: true),
    ),
    // Remaining languages — quicktype-core defaults; we care about
    // regressing *any* shape, not just the opinionated ones.
    const _Case('user_c', TargetType.c, null),
    const _Case('user_elixir', TargetType.elixir, null),
    const _Case('user_elm', TargetType.elm, null),
    const _Case(
      'user_flow_just_types',
      TargetType.flow,
      FlowRendererOptions(justTypes: true),
    ),
    const _Case('user_haskell', TargetType.haskell, null),
    const _Case('user_javascript', TargetType.javascript, null),
    const _Case('user_objc', TargetType.objc, null),
    const _Case('user_php', TargetType.php, null),
    const _Case('user_proptypes', TargetType.proptypes, null),
    const _Case('user_ruby', TargetType.ruby, null),
    const _Case('user_scala', TargetType.scala, null),
    const _Case('user_smithy', TargetType.smithy, null),
  ];

  final updateMode = Platform.environment['GOLDEN'] == 'update';

  group('golden files', () {
    final input =
        File(p.join(_goldenDir, '$_sharedInput.input.json')).readAsStringSync();

    for (final c in cases) {
      test(c.name, () async {
        final goldenPath = p.join(
          _goldenDir,
          '${c.name}.${c.target.extensions.first.substring(1)}.txt',
        );
        final actual = await QuicktypeDart.generateFromString(
          label: 'User',
          json: input,
          target: c.target,
          options: c.options,
        );
        if (updateMode) {
          File(goldenPath).writeAsStringSync(actual);
          return;
        }
        final expected = File(goldenPath).readAsStringSync();
        expect(
          actual,
          equals(expected),
          reason: 'Golden drift for ${c.name}. '
              'Regenerate with GOLDEN=update if intentional.',
        );
      });
    }
  });
}
