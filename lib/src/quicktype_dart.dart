import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'ffi/ffi_runtime.dart';
import 'models/args.dart';
import 'models/type.dart';
import 'quicktype.dart';
import 'utils/logging.dart';

/// Selects which code-generation transport [QuicktypeDart] uses.
///
/// * [auto] — prefer the in-process FFI runtime when it's available;
///   fall back to [process] otherwise. This is the default.
/// * [ffi] — require the FFI runtime. Throws [QuicktypeException] if the
///   native library isn't resolvable on this platform.
/// * [process] — always shell out to the `quicktype` Node CLI. Useful
///   for dev tooling or environments where the FFI plugin isn't built.
enum GenerateTransport { auto, ffi, process }

/// Entry point for ad-hoc, runtime JSON → typed-code conversion.
///
/// Two forms:
///
///   * [generate] — for any JSON-encodable Dart value (Map, List, etc.)
///   * [generateFromString] — for raw JSON text you already have
///
/// Example:
///
/// ```dart
/// final dartSource = await QuicktypeDart.generate(
///   label: 'User',
///   data: [{'id': 1, 'name': 'Jake'}],
///   target: TargetType.dart,
/// );
/// ```
///
/// ### Transports
///
/// Two runtimes ship, selected via [GenerateTransport]:
///
/// * **FFI** (default when available) — embedded QuickJS running
///   quicktype-core's bundled JS directly in-process. No Node required.
///   ~ms per call after one-time warm-up.
/// * **Process** — shells out to the `quicktype` Node CLI. Required when
///   passing [Arg]s until the FFI path supports them in v0.2.0-dev.2+.
///   Executable resolution: bundled `tool/node_modules/.bin/quicktype`
///   first (dev checkouts), then `quicktype` on PATH.
class QuicktypeDart {
  QuicktypeDart._();

  /// Generates typed source code from any JSON-encodable Dart value.
  ///
  /// [data] may be any value `dart:convert`'s [jsonEncode] accepts —
  /// a [Map], [List], [num], [String], [bool], or a nested composition
  /// thereof. Anything else throws [JsonUnsupportedObjectError].
  ///
  /// [label] becomes the top-level type name in the generated code.
  ///
  /// [target] selects the output language.
  ///
  /// [args] carries language-specific flags — e.g. for Dart:
  /// `[DartArgs.useFreezed..value = true, DartArgs.nullSafety..value = true]`.
  /// See the `*Args` classes for each target language. Both transports
  /// support arg passthrough as of v0.2.0-dev.7.
  ///
  /// [transport] picks the runtime — see [GenerateTransport]. Defaults to
  /// [GenerateTransport.auto].
  ///
  /// Returns the generated source as a string. Throws [QuicktypeException]
  /// on failure.
  static Future<String> generate({
    required String label,
    required Object data,
    required TargetType target,
    Iterable<Arg> args = const [],
    GenerateTransport transport = GenerateTransport.auto,
  }) =>
      generateFromString(
        label: label,
        json: jsonEncode(data),
        target: target,
        args: args,
        transport: transport,
      );

  /// Generates typed source code from a raw JSON document string.
  ///
  /// Skip `jsonEncode`-ing when you already have the document as a string
  /// (reading a file, a network response, etc). See [generate] for
  /// parameter semantics.
  static Future<String> generateFromString({
    required String label,
    required String json,
    required TargetType target,
    Iterable<Arg> args = const [],
    GenerateTransport transport = GenerateTransport.auto,
  }) async {
    final resolved = await _resolveTransport(transport, args);
    switch (resolved) {
      case GenerateTransport.ffi:
        final rt = await QtFfiRuntime.instance();
        return rt.generate(
          label: label,
          json: json,
          target: target,
          args: args,
        );
      case GenerateTransport.process:
        return _runViaProcess(
          label: label,
          json: json,
          target: target,
          args: args,
        );
      case GenerateTransport.auto:
        // _resolveTransport never returns auto.
        throw StateError('unreachable');
    }
  }

  static Future<GenerateTransport> _resolveTransport(
    GenerateTransport requested,
    Iterable<Arg> args,
  ) async {
    switch (requested) {
      case GenerateTransport.ffi:
        return GenerateTransport.ffi;
      case GenerateTransport.process:
        return GenerateTransport.process;
      case GenerateTransport.auto:
        if (await QtFfiRuntime.probe()) return GenerateTransport.ffi;
        return GenerateTransport.process;
    }
  }

  static Future<String> _runViaProcess({
    required String label,
    required String json,
    required TargetType target,
    required Iterable<Arg> args,
  }) async {
    final exe = await _resolveQuicktypeExecutable();
    final tempDir = await Directory.systemTemp.createTemp('quicktype_dart_');
    try {
      final safeLabel = _sanitizeLabel(label);
      final sourceFile = File(p.join(tempDir.path, '$safeLabel.json'));
      final targetExt = target.extensions.first;
      final targetFile = File(p.join(tempDir.path, '$safeLabel$targetExt'));

      await sourceFile.writeAsString(json);

      final argv = <String>[
        '--src', sourceFile.path,
        '--src-lang', 'json',
        '--lang', target.argName,
        '--out', targetFile.path,
      ];
      for (final arg in args) {
        argv.addAll(arg.argv());
      }

      final result = await Process.run(exe, argv);

      if (result.exitCode != 0) {
        throw QuicktypeException(
          'quicktype exited with code ${result.exitCode}: ${result.stderr}',
          command: '$exe ${argv.join(' ')}',
          exitCode: result.exitCode,
        );
      }

      if (!await targetFile.exists()) {
        throw QuicktypeException(
          'quicktype reported success but no output file was produced',
          command: '$exe ${argv.join(' ')}',
          exitCode: result.exitCode,
        );
      }

      return targetFile.readAsString();
    } finally {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (e) {
        Log.warning('Failed to clean up temp dir ${tempDir.path}: $e');
      }
    }
  }

  /// Resolves a usable `quicktype` executable, independent of caller CWD.
  ///
  /// Checks the bundled `tool/node_modules/.bin/quicktype` first; falls back
  /// to a `quicktype` found on `PATH`. Throws [QuicktypeException] if neither
  /// is available.
  static Future<String> _resolveQuicktypeExecutable() async {
    final bundled = await _resolveBundledExecutable();
    if (bundled != null) return bundled;

    final onPath = _findOnPath('quicktype');
    if (onPath != null) return onPath;

    throw QuicktypeException(
      'quicktype not found. Install it with `npm install -g quicktype`, or '
      'make sure the bundled binary exists at '
      '<package-root>/tool/node_modules/.bin/quicktype. Alternatively, use '
      '`transport: GenerateTransport.ffi` to run via the embedded '
      'QuickJS runtime (v0.2.0-dev.1+, no args support yet).',
    );
  }

  static Future<String?> _resolveBundledExecutable() async {
    try {
      final packageUri = await Isolate.resolvePackageUri(
        Uri.parse('package:quicktype_dart/quicktype_dart.dart'),
      );
      if (packageUri == null) return null;
      final packageRoot = p.dirname(p.dirname(packageUri.toFilePath()));
      final exe =
          p.join(packageRoot, 'tool', 'node_modules', '.bin', 'quicktype');
      return File(exe).existsSync() ? exe : null;
    } catch (_) {
      return null;
    }
  }

  static String? _findOnPath(String name) {
    final pathEnv = Platform.environment['PATH'];
    if (pathEnv == null || pathEnv.isEmpty) return null;
    final separator = Platform.isWindows ? ';' : ':';
    final candidates = Platform.isWindows
        ? ['$name.cmd', '$name.exe', name]
        : [name];
    for (final dir in pathEnv.split(separator)) {
      if (dir.isEmpty) continue;
      for (final cand in candidates) {
        final full = p.join(dir, cand);
        if (File(full).existsSync()) return full;
      }
    }
    return null;
  }

  static String _sanitizeLabel(String label) {
    final cleaned = label.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    if (cleaned.isEmpty) return 'Generated';
    if (RegExp(r'^[0-9]').hasMatch(cleaned)) return 'T_$cleaned';
    return cleaned;
  }
}
