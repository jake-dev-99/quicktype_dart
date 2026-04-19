// Throwaway smoke test — not part of the published package (excluded via
// .pubignore). Run during local development with:
//
//   dart run tool/smoke/smoke.dart

import 'dart:io';

import 'package:quicktype_dart/quicktype_dart.dart';

Future<void> main() async {
  Directory.current = Directory.systemTemp;
  stdout.writeln('CWD: ${Directory.current.path}');

  // 1) Array-of-objects
  final fromList = await QuicktypeDart.generate(
    label: 'Smoke',
    data: [
      {'name': 'Jake', 'age': 42, 'active': true},
    ],
    target: TargetType.dart,
  );
  _assert(fromList.contains('class Smoke'), 'list-shape missing `class Smoke`');
  _assert(
      fromList.contains('fromJson'), 'list-shape missing default `fromJson`');

  // 2) Single object (widened signature accepts this)
  final fromMap = await QuicktypeDart.generate(
    label: 'Smoke',
    data: {'name': 'Jake', 'age': 42, 'active': true},
    target: TargetType.dart,
  );
  _assert(fromMap.contains('class Smoke'), 'map-shape missing `class Smoke`');

  // 3) Raw JSON string
  final fromString = await QuicktypeDart.generateFromString(
    label: 'Smoke',
    json: '{"name":"Jake","age":42,"active":true}',
    target: TargetType.dart,
  );
  _assert(
      fromString.contains('class Smoke'), 'string-shape missing `class Smoke`');

  // 4) Typed options plumbing: --just-types strips the serialization
  //    scaffolding.
  final typesOnly = await QuicktypeDart.generate(
    label: 'Smoke',
    data: {'name': 'Jake', 'age': 42, 'active': true},
    target: TargetType.dart,
    options: const DartRendererOptions(justTypes: true),
  );
  _assert(typesOnly.contains('class Smoke'), 'typesOnly missing `class Smoke`');
  _assert(!typesOnly.contains('fromJson'),
      'typesOnly contained `fromJson` — --just-types was NOT plumbed through');

  stdout.writeln('---');
  stdout.writeln('OK — list(${fromList.length}) map(${fromMap.length}) '
      'string(${fromString.length}) justTypes(${typesOnly.length}) chars');
}

void _assert(bool condition, String message) {
  if (!condition) {
    stderr.writeln('FAIL: $message');
    exit(1);
  }
}
