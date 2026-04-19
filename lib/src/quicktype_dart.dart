import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'models/args.dart';
import 'models/type.dart';
import 'quicktype.dart';
import 'utils/logging.dart';

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
///   args: [DartArgs.useFreezed..value = true],
/// );
/// ```
///
/// ### Executable resolution
///
/// Shells out to the `quicktype` Node CLI. Resolution order:
///
///   1. A bundled binary at `<package-root>/tool/node_modules/.bin/quicktype`
///      — used when running from a dev checkout of this package.
///   2. The `quicktype` executable on the user's `PATH` — the typical
///      production path, requires `npm install -g quicktype`.
///
/// Throws [QuicktypeException] with install instructions if neither is
/// available.
///
/// v0.2.0 will add an FFI path (QuickJS-embedded quicktype-core) that
/// removes the Node dependency entirely.
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
  /// See the `*Args` classes for each target language.
  ///
  /// Returns the generated source as a string. Throws [QuicktypeException]
  /// on subprocess failure.
  static Future<String> generate({
    required String label,
    required Object data,
    required TargetType target,
    Iterable<Arg> args = const [],
  }) =>
      generateFromString(
        label: label,
        json: jsonEncode(data),
        target: target,
        args: args,
      );

  /// Generates typed source code from a raw JSON document string.
  ///
  /// Skip `jsonEncode`-ing when you already have the document as a string
  /// (reading a file, a network response, etc).
  ///
  /// See [generate] for parameter semantics.
  static Future<String> generateFromString({
    required String label,
    required String json,
    required TargetType target,
    Iterable<Arg> args = const [],
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
    // 1) Prefer the bundled binary when running inside a dev checkout.
    final bundled = await _resolveBundledExecutable();
    if (bundled != null) return bundled;

    // 2) Fall back to `quicktype` on PATH.
    final onPath = _findOnPath('quicktype');
    if (onPath != null) return onPath;

    throw QuicktypeException(
      'quicktype not found. Install it with `npm install -g quicktype`, or '
      'make sure the bundled binary exists at '
      '<package-root>/tool/node_modules/.bin/quicktype.',
    );
  }

  static Future<String?> _resolveBundledExecutable() async {
    try {
      final packageUri = await Isolate.resolvePackageUri(
        Uri.parse('package:quicktype_dart/quicktype_dart.dart'),
      );
      if (packageUri == null) return null;
      // packageUri → .../quicktype_dart/lib/quicktype_dart.dart
      // package root → .../quicktype_dart/
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
