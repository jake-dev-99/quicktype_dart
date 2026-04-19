// Hand-written FFI bindings to the qt_shim C library.
//
// Exposes the per-runtime API as the primary surface. The older
// process-global API is available via [QtShimBindings.qtInit] /
// [QtShimBindings.qtConvertGlobal] for callers still on the dev.1..dev.6
// pattern; new code should prefer the per-runtime functions.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

// --- Per-runtime API -----------------------------------------------------

/// `QtRuntime* qt_runtime_create(void)` — creates a runtime and loads the
/// embedded bundle. Returns `nullptr` on failure.
typedef QtRuntimeCreateNative = Pointer<Void> Function();
typedef QtRuntimeCreate = Pointer<Void> Function();

/// `void qt_runtime_destroy(QtRuntime*)` — tears down a runtime. Safe with
/// `nullptr`.
typedef QtRuntimeDestroyNative = Void Function(Pointer<Void>);
typedef QtRuntimeDestroy = void Function(Pointer<Void>);

/// `char* qt_runtime_convert(QtRuntime*, const char* lang_json,
///                           const char* name_json, const char* sample_json,
///                           const char* options_json)`
typedef QtRuntimeConvertNative = Pointer<Utf8> Function(
    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef QtRuntimeConvert = Pointer<Utf8> Function(
    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

/// `void qt_free(char*)` — frees strings returned from qt_runtime_convert.
typedef QtFreeNative = Void Function(Pointer<Utf8>);
typedef QtFree = void Function(Pointer<Utf8>);

// --- Legacy process-global API (kept for one dev cycle) ------------------

typedef QtInitNative = Int32 Function();
typedef QtInit = int Function();

typedef QtConvertNative = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef QtConvert = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

typedef QtShutdownNative = Void Function();
typedef QtShutdown = void Function();

/// Lazily-resolved function pointers into the `qt_shim` native library.
class QtShimBindings {
  QtShimBindings(this._lib)
      : qtRuntimeCreate = _lib.lookupFunction<QtRuntimeCreateNative,
            QtRuntimeCreate>('qt_runtime_create'),
        qtRuntimeDestroy = _lib.lookupFunction<QtRuntimeDestroyNative,
            QtRuntimeDestroy>('qt_runtime_destroy'),
        qtRuntimeConvert = _lib.lookupFunction<QtRuntimeConvertNative,
            QtRuntimeConvert>('qt_runtime_convert'),
        qtFree = _lib.lookupFunction<QtFreeNative, QtFree>('qt_free'),
        qtInit = _lib.lookupFunction<QtInitNative, QtInit>('qt_init'),
        qtConvertGlobal = _lib
            .lookupFunction<QtConvertNative, QtConvert>('qt_convert'),
        qtShutdown = _lib
            .lookupFunction<QtShutdownNative, QtShutdown>('qt_shutdown');

  // ignore: unused_field
  final DynamicLibrary _lib;

  final QtRuntimeCreate qtRuntimeCreate;
  final QtRuntimeDestroy qtRuntimeDestroy;
  final QtRuntimeConvert qtRuntimeConvert;
  final QtFree qtFree;

  // Legacy — prefer the per-runtime API.
  final QtInit qtInit;
  final QtConvert qtConvertGlobal;
  final QtShutdown qtShutdown;
}
