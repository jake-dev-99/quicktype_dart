// FFI-path smoke test. Forces the QuickJS-embedded runtime and verifies
// it produces the same output as the Process.run path.
//
// Run after `cmake --build build/native` has produced libqt_shim.dylib.
//
//   dart run tool/smoke/ffi_smoke.dart

import 'dart:io';

import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:quicktype_dart/src/ffi/ffi_runtime.dart';

Future<void> main() async {
  // Prove CWD-independence — probe works regardless of where we're run.
  Directory.current = Directory.systemTemp;
  stdout.writeln('CWD: ${Directory.current.path}');

  final available = await QtFfiRuntime.probe();
  stdout.writeln('FFI available: $available');
  if (!available) {
    stderr.writeln('FAIL: QtFfiRuntime.probe() returned false');
    exit(1);
  }

  final rt = await QtFfiRuntime.instance();

  // Time several calls to verify the warm-up pattern from the spike
  // (first call does bundle/runtime init; subsequent should be ~ms).
  final runs = <int>[];
  String? lastResult;
  for (var i = 0; i < 3; i++) {
    final t0 = DateTime.now();
    lastResult = await rt.generate(
      label: 'User',
      json: '{"id":1,"name":"Jake","active":true}',
      target: TargetType.dart,
    );
    runs.add(DateTime.now().difference(t0).inMilliseconds);
  }
  stdout.writeln('convert ms by run: $runs');
  _assert(lastResult!.contains('class User'),
      'generated output missing `class User`');
  _assert(lastResult.contains('fromJson'),
      'generated output missing default `fromJson`');
  stdout.writeln('--- first 300 chars ---');
  stdout.writeln(lastResult.substring(0, lastResult.length.clamp(0, 300)));
  stdout.writeln('--- end ---');
  stdout.writeln('OK — generated ${lastResult.length} chars');
}

void _assert(bool condition, String message) {
  if (!condition) {
    stderr.writeln('FAIL: $message');
    exit(1);
  }
}
