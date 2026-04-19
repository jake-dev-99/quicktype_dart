// Smoke test for the new typed `RendererOptions` path.
//
//   dart run bin/options_smoke.dart

import 'dart:io';

import 'package:quicktype_dart/quicktype_dart.dart';

Future<void> main() async {
  // Typed options — preferred path.
  final withFreezed = await QuicktypeDart.generate(
    label: 'User',
    data: {'id': 1, 'name': 'Jake'},
    target: TargetType.dart,
    options: const DartRendererOptions(justTypes: true, nullSafety: true),
  );
  _assert(withFreezed.contains('class User'),
      'typed-options output missing `class User`');
  _assert(!withFreezed.contains('fromJson'),
      'typed-options + justTypes should strip fromJson');

  // Legacy Args path — still honored alongside typed options.
  final viaArgs = await QuicktypeDart.generate(
    label: 'User',
    data: {'id': 1, 'name': 'Jake'},
    target: TargetType.dart,
    args: [DartArgs.justTypes..value = true],
  );
  _assert(viaArgs == withFreezed,
      'typed-options and args-based paths should produce identical output');

  // Mixed: options + args (args overrides on key collision — legacy wins).
  final mixed = await QuicktypeDart.generate(
    label: 'User',
    data: {'id': 1, 'name': 'Jake'},
    target: TargetType.dart,
    options: const DartRendererOptions(justTypes: false),
    args: [DartArgs.justTypes..value = true], // overrides options → justTypes=true
  );
  _assert(!mixed.contains('fromJson'),
      'mixed: args should override options on key collision');

  stdout.writeln('OK — typed options honored, args-override semantics correct '
      '(${withFreezed.length} chars)');
}

void _assert(bool condition, String message) {
  if (!condition) {
    stderr.writeln('FAIL: $message');
    exit(1);
  }
}
