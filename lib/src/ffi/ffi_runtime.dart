import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../models/args.dart';
import '../models/type.dart';
import '../quicktype.dart';
import '../utils/logging.dart';
import 'qt_shim_bindings.dart';

/// Embedded QuickJS + quicktype-core runtime, called via FFI.
///
/// The FFI path is **opt-in for v0.2.0-dev.1** — it only runs on macOS
/// today, and [QuicktypeDart.generate] tries it first then falls back to
/// `Process.run`. To force the FFI path (e.g. in tests), call
/// [QtFfiRuntime.instance] directly.
///
/// The runtime lazy-initializes on first call. It's a **process-global
/// singleton** — QuickJS runtimes are single-threaded and this first cut
/// doesn't support multi-isolate access. Revisit in a later phase.
class QtFfiRuntime {
  QtFfiRuntime._(this._bindings);

  static QtFfiRuntime? _instance;
  static Object? _resolveError;

  final QtShimBindings _bindings;
  bool _initialized = false;

  /// Returns the live runtime, or throws [QuicktypeException] if the native
  /// library can't be loaded on this platform.
  static Future<QtFfiRuntime> instance() async {
    if (_instance != null) return _instance!;
    if (_resolveError != null) {
      throw QuicktypeException('FFI unavailable: $_resolveError');
    }
    try {
      final lib = await _openLibrary();
      _instance = QtFfiRuntime._(QtShimBindings(lib));
      return _instance!;
    } catch (e) {
      _resolveError = e;
      throw QuicktypeException('FFI unavailable: $e');
    }
  }

  /// Returns `true` if [instance] is known to be callable. Doesn't attempt
  /// to resolve the library — use in guards to avoid surfacing an error
  /// when the caller can trivially fall back.
  static bool get isAvailable => _instance != null;

  /// Attempts to resolve the native library without throwing; returns
  /// `true` if it's now available. Intended for one-time capability
  /// probing before dispatching the FFI path.
  static Future<bool> probe() async {
    if (_instance != null) return true;
    if (_resolveError != null) return false;
    try {
      await instance();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Generates typed source code via the embedded runtime. Mirrors
  /// [QuicktypeDart.generateFromString] but stays entirely in-process —
  /// no subprocess, no `quicktype` on PATH required.
  Future<String> generate({
    required String label,
    required String json,
    required TargetType target,
    Iterable<Arg> args = const [],
  }) async {
    if (!_initialized) {
      final rc = _bindings.qtInit();
      if (rc != 0) {
        throw QuicktypeException('qt_init failed with code $rc');
      }
      _initialized = true;
    }

    // Caller of qt_convert passes three pre-encoded JSON string literals.
    // Anything language/arg-specific beyond the plain convertJSON path is
    // not yet forwarded into the QuickJS side — v0.2.0-dev.1 is the basic
    // lang/name/json conversion. Arg plumbing for FFI lands in a later dev.
    if (args.isNotEmpty) {
      Log.warning(
        'args are not yet plumbed through the FFI path — they will be '
        'ignored. Use Process.run for arg support in v0.2.0-dev.1.',
        'QtFfiRuntime',
      );
    }

    final langP = jsonEncode(target.argName).toNativeUtf8();
    final nameP = jsonEncode(label).toNativeUtf8();
    final jsonP = jsonEncode(json).toNativeUtf8();
    try {
      final resultP = _bindings.qtConvert(langP, nameP, jsonP);
      if (resultP == nullptr) {
        throw QuicktypeException(
          'qt_convert returned null — the embedded runtime encountered a '
          'catastrophic error. Consider filing an issue with the input.',
        );
      }
      final result = resultP.toDartString();
      _bindings.qtFree(resultP);
      return result;
    } finally {
      calloc.free(langP);
      calloc.free(nameP);
      calloc.free(jsonP);
    }
  }

  /// Resolves the shared library across the platforms v0.2.0-dev.1 supports.
  /// Each layer below raises a [QuicktypeException] on failure.
  static Future<DynamicLibrary> _openLibrary() async {
    // 1) Standalone dev build (`cmake --build build/native`) — tried first
    //    because it's the only path that works today when running tests
    //    against the repo without a Flutter app bundle.
    final devPath = await _devBuildPath();
    if (devPath != null && File(devPath).existsSync()) {
      return DynamicLibrary.open(devPath);
    }

    // 2) Flutter plugin install — loads via `@rpath` resolution.
    //    (This branch is what ships; dev branch above is the contributor path.)
    final pluginName = _flutterLibName();
    try {
      return DynamicLibrary.open(pluginName);
    } catch (e) {
      throw QuicktypeException(
        'Unable to resolve qt_shim native library. Tried dev build at '
        '"$devPath" and plugin-style "$pluginName". Error: $e',
      );
    }
  }

  /// Returns the on-disk dev-build path if we can locate it via the
  /// quicktype_dart package root, otherwise null.
  static Future<String?> _devBuildPath() async {
    try {
      final packageUri = await Isolate.resolvePackageUri(
        Uri.parse('package:quicktype_dart/quicktype_dart.dart'),
      );
      if (packageUri == null) return null;
      // packageUri → .../quicktype_dart/lib/quicktype_dart.dart
      final packageRoot = p.dirname(p.dirname(packageUri.toFilePath()));
      final ext = _dylibExtension();
      return p.join(packageRoot, 'build', 'native', 'libqt_shim$ext');
    } catch (_) {
      return null;
    }
  }

  static String _flutterLibName() {
    // Flutter compiles the plugin's native code into a framework/library
    // named after the plugin's pod/pubspec `name`, not our internal
    // `qt_shim` CMake target. On macOS/iOS that's a framework; on the
    // Unixes it's `libquicktype_dart.so`; on Windows `quicktype_dart.dll`.
    if (Platform.isMacOS || Platform.isIOS) {
      return 'quicktype_dart.framework/quicktype_dart';
    }
    if (Platform.isLinux || Platform.isAndroid) return 'libquicktype_dart.so';
    if (Platform.isWindows) return 'quicktype_dart.dll';
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  static String _dylibExtension() {
    if (Platform.isMacOS || Platform.isIOS) return '.dylib';
    if (Platform.isWindows) return '.dll';
    return '.so';
  }
}
