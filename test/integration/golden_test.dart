// Golden-file tests for the public `QuicktypeDart.generate` surface.
//
// Each golden consists of:
//   * test/integration/goldens/<name>.input.json   — payload
//   * test/integration/goldens/<name>.<lang>.txt   — expected output
//
// To update a golden after an intentional output change, re-run with
// the `GOLDEN=update` environment variable:
//
//     GOLDEN=update dart test test/integration/golden_test.dart \
//       --tags=integration
//
// Any quicktype-core upgrade or renderer-option change that affects
// output has to land with a matching golden update in the same PR.

@Tags(['integration'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

const _goldenDir = 'test/integration/goldens';

class _Case {
  const _Case(this.name, this.target, this.options);
  final String name;
  final TargetType target;
  final RendererOptions? options;
}

void main() {
  final cases = <_Case>[
    const _Case(
      'user_dart_just_types',
      TargetType.dart,
      DartRendererOptions(justTypes: true),
    ),
  ];

  final updateMode = Platform.environment['GOLDEN'] == 'update';

  group('golden files', () {
    for (final c in cases) {
      test(c.name, () async {
        final inputPath = p.join(_goldenDir, '${c.name}.input.json');
        final goldenPath = p.join(_goldenDir,
            '${c.name}.${c.target.extensions.first.substring(1)}.txt');
        final input = File(inputPath).readAsStringSync();
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
        expect(actual, equals(expected),
            reason: 'Golden drift for ${c.name}. '
                'Regenerate with GOLDEN=update if intentional.');
      });
    }
  });
}
