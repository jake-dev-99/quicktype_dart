import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../bundle_source.dart';
import '../models/type.dart';
import '../quicktype.dart';
import '../quicktype_dart.dart';
import 'native_bundle_cache.dart';
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
  // Guards concurrent callers of [instance] so two simultaneous init
  // attempts share the same in-flight runtime instead of each allocating
  // their own and leaking one.
  static Completer<QtFfiRuntime>? _sharedInstancePending;

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
  static Future<QtFfiRuntime> instance() {
    final existing = _sharedInstance;
    if (existing != null && !existing._disposed) {
      return Future.value(existing);
    }
    final pending = _sharedInstancePending;
    if (pending != null) return pending.future;

    final completer = Completer<QtFfiRuntime>();
    _sharedInstancePending = completer;
    create().then((rt) {
      _sharedInstance = rt;
      _sharedInstancePending = null;
      completer.complete(rt);
    }, onError: (Object e, StackTrace st) {
      _sharedInstancePending = null;
      completer.completeError(e, st);
    });
    return completer.future;
  }

  /// Creates a fresh runtime backed by a new QuickJS instance. The caller
  /// owns the returned runtime and should [dispose] it when done, or rely
  /// on Dart GC finalization.
  ///
  /// [bundleSource] controls which quicktype-core JS is loaded into the
  /// runtime. Defaults to [QuicktypeDart.bundleSource] — i.e. respects any
  /// process-wide override set via [QuicktypeDart.setBundleSource].
  ///
  /// With [EmbeddedBundleSource], the compiled-in bundle is loaded (fails
  /// if the library was built with `-DQT_NO_EMBEDDED_BUNDLE`).
  /// With [RemoteBundleSource], the JS is fetched via HTTP (cached on-disk
  /// by URL hash) and handed to the runtime directly — shrinks the binary
  /// when paired with a no-embed build.
  static Future<QtFfiRuntime> create({BundleSource? bundleSource}) async {
    final source = bundleSource ?? QuicktypeDart.bundleSource;
    final bindings = await _resolveBindings();
    final handle = bindings.qtRuntimeCreate();
    if (handle == nullptr) {
      throw QuicktypeException(
          'qt_runtime_create returned null — the embedded QuickJS runtime '
          'failed to initialize.');
    }
    try {
      await _loadBundle(bindings, handle, source);
    } catch (_) {
      bindings.qtRuntimeDestroy(handle);
      rethrow;
    }
    return QtFfiRuntime._(bindings, handle);
  }

  static Future<void> _loadBundle(QtShimBindings bindings, Pointer<Void> handle,
      BundleSource source) async {
    switch (source) {
      case EmbeddedBundleSource():
        final rc = bindings.qtRuntimeLoadEmbedded(handle);
        if (rc == -2) {
          throw QuicktypeException(
            'qt_runtime_load_embedded: this quicktype_dart native library '
            'was built with QT_NO_EMBEDDED_BUNDLE. Configure a '
            'BundleSource.remote(...) via QuicktypeDart.setBundleSource() '
            'before the first generate call.',
          );
        }
        if (rc != 0) {
          throw QuicktypeException(
              'qt_runtime_load_embedded failed with code $rc.');
        }
      case RemoteBundleSource(:final url, :final integrity):
        final js = await fetchAndCacheBundle(url, integrity);
        using((arena) {
          final jsP = js.toNativeUtf8(allocator: arena);
          final rc = bindings.qtRuntimeLoadBundle(handle, jsP, jsP.length);
          if (rc != 0) {
            throw QuicktypeException(
                'qt_runtime_load_bundle failed with code $rc for $url.');
          }
        });
    }
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

    // Arena guarantees every allocation is freed on any return path,
    // including when jsonEncode throws mid-allocation.
    return using((arena) {
      final langP = jsonEncode(target.argName).toNativeUtf8(allocator: arena);
      final nameP = jsonEncode(label).toNativeUtf8(allocator: arena);
      final jsonP = jsonEncode(json).toNativeUtf8(allocator: arena);
      final optsP = jsonEncode(rendererOptions).toNativeUtf8(allocator: arena);

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
    });
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
    if (identical(_sharedInstance, this)) {
      _sharedInstance = null;
      _sharedInstancePending = null;
    }
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
      return p.join(
          packageRoot, 'build', 'native', '${prefix}quicktype_dart$ext');
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
