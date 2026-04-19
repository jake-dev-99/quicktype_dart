@Tags(['integration'])
library;

import 'dart:io';

import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

/// End-to-end test — requires the quicktype CLI on PATH or bundled locally.
/// Run with `dart test --tags=integration`.
void main() {
  group('QuicktypeDart.generate (integration)', () {
    test('produces a Dart class from a Map payload', () async {
      final out = await QuicktypeDart.generate(
        label: 'User',
        data: {'id': 1, 'name': 'Jake'},
        target: TargetType.dart,
      );
      expect(out, contains('class User'));
      expect(out, contains('fromJson'));
    });

    test('--just-types flag strips the serialization scaffolding', () async {
      final withSerde = await QuicktypeDart.generate(
        label: 'Foo',
        data: {'x': 1},
        target: TargetType.dart,
      );
      final justTypes = await QuicktypeDart.generate(
        label: 'Foo',
        data: {'x': 1},
        target: TargetType.dart,
        args: [DartArgs.justTypes..value = true],
      );
      expect(withSerde, contains('fromJson'));
      expect(justTypes, isNot(contains('fromJson')));
      expect(justTypes, contains('class Foo'));
    });

    test('generateFromString accepts raw JSON text', () async {
      final out = await QuicktypeDart.generateFromString(
        label: 'User',
        json: '{"id":1,"name":"Jake"}',
        target: TargetType.dart,
      );
      expect(out, contains('class User'));
    });
  }, skip: _quicktypeUnavailable());

  // Check at load time — returns a skip reason string or null.
  // Kept out-of-line to keep the test bodies readable.
}

/// Returns a skip message if quicktype isn't resolvable, else null.
String? _quicktypeUnavailable() {
  final pathEnv = Platform.environment['PATH'] ?? '';
  final sep = Platform.isWindows ? ';' : ':';
  for (final dir in pathEnv.split(sep)) {
    if (dir.isEmpty) continue;
    final candidates = Platform.isWindows
        ? ['quicktype.cmd', 'quicktype.exe', 'quicktype']
        : ['quicktype'];
    for (final cand in candidates) {
      if (File('$dir${Platform.pathSeparator}$cand').existsSync()) return null;
    }
  }
  // Bundled fallback.
  if (File('tool/node_modules/.bin/quicktype').existsSync()) return null;
  return 'quicktype CLI not on PATH or bundled; skipping integration tests';
}
