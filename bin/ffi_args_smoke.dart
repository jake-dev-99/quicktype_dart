// Smoke test: arg plumbing through the FFI path.
//
//   dart run bin/ffi_args_smoke.dart
import 'dart:io';

import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:quicktype_dart/src/ffi/ffi_runtime.dart';

Future<void> main() async {
  await QtFfiRuntime.instance();  // force resolve

  // Plain — produces fromJson/toJson scaffolding.
  final plain = await QuicktypeDart.generate(
    label: 'User',
    data: {'id': 1, 'name': 'Jake'},
    target: TargetType.dart,
    transport: GenerateTransport.ffi,
  );
  _assert(plain.contains('fromJson'),
      'plain FFI output missing fromJson — regression');

  // With --just-types → no fromJson.
  final justTypes = await QuicktypeDart.generate(
    label: 'User',
    data: {'id': 1, 'name': 'Jake'},
    target: TargetType.dart,
    transport: GenerateTransport.ffi,
    args: [DartArgs.justTypes..value = true],
  );
  _assert(!justTypes.contains('fromJson'),
      'FFI + --just-types produced fromJson — arg did NOT reach quicktype-core');
  _assert(justTypes.contains('class User'),
      'FFI + --just-types missing class User');

  stdout.writeln(
      'OK — plain (${plain.length}) justTypes (${justTypes.length}) chars '
      '— arg plumbing through FFI works');
}

void _assert(bool condition, String message) {
  if (!condition) {
    stderr.writeln('FAIL: $message');
    exit(1);
  }
}
