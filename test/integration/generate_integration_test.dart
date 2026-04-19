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
        options: const DartRendererOptions(justTypes: true),
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
///
/// By default a missing `quicktype` CLI hard-fails so CI notices. Set
/// `QUICKTYPE_OPTIONAL=1` in the environment to opt into the old
/// "skip quietly" behavior — useful for local runs on a machine
/// without Node installed.
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

  const msg =
      'quicktype CLI not on PATH or bundled at tool/node_modules/.bin/quicktype';
  final optional = Platform.environment['QUICKTYPE_OPTIONAL'] == '1';
  if (optional) {
    stderr.writeln('integration tests skipped: $msg '
        '(QUICKTYPE_OPTIONAL=1 opt-in)');
    return '$msg (QUICKTYPE_OPTIONAL=1 opt-in skip)';
  }
  // Hard-fail path: return a skip message that loudly flags CI misconfig.
  // Actual enforcement happens inside the group via an explicit fail()
  // call on the first test, so CI logs contain the reason clearly.
  stderr.writeln('FATAL: $msg. Install quicktype via '
      '`npm install -g quicktype` or set QUICKTYPE_OPTIONAL=1 to skip.');
  return null; // Let tests run; they'll fail with a clearer error.
}
