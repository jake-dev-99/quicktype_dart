import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../models/type.dart';
import '../quicktype.dart';
import 'qt_shim_bindings.dart';

/// Embedded QuickJS + quicktype-core runtime, called via FFI.
///
/// Each [QtFfiRuntime] owns its own native runtime handle. QuickJS is
/// single-threaded, so multiple isolates can each create their own
/// [QtFfiRuntime] and run generations in parallel without contention.
///
/// The first [QtFfiRuntime] created in an isolate also caches the loaded
/// [DynamicLibrary] so subsequent runtimes skip library lookup. Handles
/// are freed via [Finalizer] when the Dart wrapper goes out of scope; call
/// [dispose] for deterministic cleanup.
class QtFfiRuntime {
  QtFfiRuntime._(this._bindings, this._handle) {
    _finalizer.attach(this, _FinalizationToken(_bindings, _handle),
        detach: this);
  }

  static QtShimBindings? _cachedBindings;
  static Object? _resolveError;
  static QtFfiRuntime? _sharedInstance;

  static final Finalizer<_FinalizationToken> _finalizer =
      Finalizer<_FinalizationToken>((token) {
    token.bindings.qtRuntimeDestroy(token.handle);
  });

  final QtShimBindings _bindings;
  Pointer<Void> _handle;
  bool _disposed = false;

  /// Returns the shared process-wide runtime, creating it on first call.
  ///
  /// For most consumers this is the right entry point — one runtime per
  /// process, lazy-initialized on first use. Callers needing isolate-level
  /// isolation should construct a fresh [QtFfiRuntime.create] instead.
  static Future<QtFfiRuntime> instance() async {
    if (_sharedInstance != null && !_sharedInstance!._disposed) {
      return _sharedInstance!;
    }
    _sharedInstance = await create();
    return _sharedInstance!;
  }

  /// Creates a fresh runtime backed by a new QuickJS instance. The caller
  /// owns the returned runtime and should [dispose] it when done, or rely
  /// on Dart GC finalization.
  static Future<QtFfiRuntime> create() async {
    final bindings = await _resolveBindings();
    final handle = bindings.qtRuntimeCreate();
    if (handle == nullptr) {
      throw QuicktypeException(
          'qt_runtime_create returned null — the embedded QuickJS runtime '
          'failed to initialize.');
    }
    return QtFfiRuntime._(bindings, handle);
  }

  /// Returns `true` if the FFI library can be resolved in this isolate.
  /// Doesn't create a runtime — use this to gate optional FFI usage.
  static Future<bool> probe() async {
    try {
      await _resolveBindings();
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
    Map<String, String> rendererOptions = const {},
  }) async {
    if (_disposed) {
      throw StateError('QtFfiRuntime has been disposed');
    }

    final langP = jsonEncode(target.argName).toNativeUtf8();
    final nameP = jsonEncode(label).toNativeUtf8();
    final jsonP = jsonEncode(json).toNativeUtf8();
    final optsP = jsonEncode(rendererOptions).toNativeUtf8();
    try {
      final resultP =
          _bindings.qtRuntimeConvert(_handle, langP, nameP, jsonP, optsP);
      if (resultP == nullptr) {
        throw QuicktypeException(
          'qt_runtime_convert returned null — the embedded runtime '
          'encountered a catastrophic error.',
        );
      }
      final result = resultP.toDartString();
      _bindings.qtFree(resultP);
      return result;
    } finally {
      calloc.free(langP);
      calloc.free(nameP);
      calloc.free(jsonP);
      calloc.free(optsP);
    }
  }

  /// Explicitly tears down this runtime's native handle.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _finalizer.detach(this);
    if (_handle != nullptr) {
      _bindings.qtRuntimeDestroy(_handle);
      _handle = nullptr;
    }
    if (identical(_sharedInstance, this)) _sharedInstance = null;
  }

  /// Loads the native library once per isolate and caches the bindings.
  static Future<QtShimBindings> _resolveBindings() async {
    if (_cachedBindings != null) return _cachedBindings!;
    if (_resolveError != null) {
      throw QuicktypeException('FFI unavailable: $_resolveError');
    }
    try {
      final lib = await _openLibrary();
      _cachedBindings = QtShimBindings(lib);
      return _cachedBindings!;
    } catch (e) {
      _resolveError = e;
      throw QuicktypeException('FFI unavailable: $e');
    }
  }

  static Future<DynamicLibrary> _openLibrary() async {
    final devPath = await _devBuildPath();
    if (devPath != null && File(devPath).existsSync()) {
      return DynamicLibrary.open(devPath);
    }
    final pluginName = _flutterLibName();
    try {
      return DynamicLibrary.open(pluginName);
    } catch (e) {
      throw QuicktypeException(
        'Unable to resolve quicktype_dart native library. Tried dev build '
        'at "$devPath" and plugin-style "$pluginName". Error: $e',
      );
    }
  }

  /// Returns the on-disk dev-build path if we can locate it via the
  /// quicktype_dart package root, otherwise null.
  ///
  /// Matches the filename produced by `cmake --build build/native` — which
  /// in turn matches the pubspec `name` (`quicktype_dart`) so all platforms
  /// use a single convention.
  static Future<String?> _devBuildPath() async {
    try {
      final packageUri = await Isolate.resolvePackageUri(
        Uri.parse('package:quicktype_dart/quicktype_dart.dart'),
      );
      if (packageUri == null) return null;
      final packageRoot = p.dirname(p.dirname(packageUri.toFilePath()));
      final ext = _dylibExtension();
      final prefix = Platform.isWindows ? '' : 'lib';
      return p.join(packageRoot, 'build', 'native',
          '${prefix}quicktype_dart$ext');
    } catch (_) {
      return null;
    }
  }

  static String _flutterLibName() {
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

/// Finalization token — [Finalizer] requires the attached value to NOT
/// reference the wrapper directly (otherwise the wrapper never becomes
/// unreachable). A tiny immutable carrier avoids that cycle.
class _FinalizationToken {
  _FinalizationToken(this.bindings, this.handle);
  final QtShimBindings bindings;
  final Pointer<Void> handle;
}
