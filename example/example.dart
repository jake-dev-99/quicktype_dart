// Runtime example: convert an in-memory JSON payload into a Dart class.
//
// Prereqs:
//   - `quicktype` CLI installed (`npm install -g quicktype`)
// Run:
//   dart run example.dart

import 'package:quicktype_dart/quicktype_dart.dart';

Future<void> main() async {
  // 1) Simplest case — generate from a Map.
  final source = await QuicktypeDart.generate(
    label: 'User',
    data: {
      'id': 42,
      'name': 'Jake',
      'roles': ['admin', 'editor'],
      'profile': {'age': 33, 'active': true},
    },
    target: TargetType.dart,
  );
  print('--- QuicktypeDart.generate (Map → Dart) ---\n$source');

  // 2) Same input, different target language.
  final kotlin = await QuicktypeDart.generate(
    label: 'User',
    data: {'id': 42, 'name': 'Jake'},
    target: TargetType.kotlin,
  );
  print('--- same data → Kotlin ---\n$kotlin');

  // 3) Pass language-specific flags via typed args (BoolArg/EnumArg/StringArg).
  final justTypes = await QuicktypeDart.generate(
    label: 'User',
    data: {'id': 42, 'name': 'Jake'},
    target: TargetType.dart,
    args: [DartArgs.justTypes..value = true],
  );
  print('--- Dart with --just-types ---\n$justTypes');
}
