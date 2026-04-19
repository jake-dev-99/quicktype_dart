// Smoke test: multiple QtFfiRuntime instances don't interfere.
//
//   dart run tool/smoke/ffi_isolate_smoke.dart

import 'dart:io';

import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:quicktype_dart/src/ffi/ffi_runtime.dart';

Future<void> main() async {
  // Two independent runtimes — mimics two isolates each owning its own.
  final a = await QtFfiRuntime.create();
  final b = await QtFfiRuntime.create();

  final outA = await a.generate(
    label: 'Alpha',
    json: '{"id":1}',
    target: TargetType.dart,
  );
  final outB = await b.generate(
    label: 'Beta',
    json: '{"id":2}',
    target: TargetType.dart,
    rendererOptions: const {'just-types': 'true'},
  );

  _assert(outA.contains('class Alpha'), 'Alpha missing class');
  _assert(outA.contains('fromJson'), 'Alpha should have default fromJson');
  _assert(outB.contains('class Beta'), 'Beta missing class');
  _assert(
      !outB.contains('fromJson'), 'Beta --just-types should strip fromJson');

  // Independence check: calling back into A shouldn't be affected by B's
  // prior call with different options.
  final outA2 = await a.generate(
    label: 'Gamma',
    json: '{"id":3}',
    target: TargetType.dart,
  );
  _assert(outA2.contains('class Gamma'), 'Gamma missing class');
  _assert(outA2.contains('fromJson'),
      'Gamma should have fromJson — runtimes may be sharing state');

  a.dispose();
  b.dispose();

  // And after disposal, a method call should throw cleanly (not crash).
  try {
    await a.generate(label: 'PostDispose', json: '{}', target: TargetType.dart);
    stderr.writeln('FAIL: expected StateError after dispose');
    exit(1);
  } on StateError {
    // expected
  }

  stdout.writeln('OK — two runtimes isolated; post-dispose guard works');
}

void _assert(bool condition, String message) {
  if (!condition) {
    stderr.writeln('FAIL: $message');
    exit(1);
  }
}
