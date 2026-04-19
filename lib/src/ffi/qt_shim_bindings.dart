// Hand-written FFI bindings to the qt_shim C library.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

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

/// Lazily-resolved function pointers into the `qt_shim` native library.
class QtShimBindings {
  QtShimBindings(this._lib)
      : qtRuntimeCreate = _lib.lookupFunction<QtRuntimeCreateNative,
            QtRuntimeCreate>('qt_runtime_create'),
        qtRuntimeDestroy = _lib.lookupFunction<QtRuntimeDestroyNative,
            QtRuntimeDestroy>('qt_runtime_destroy'),
        qtRuntimeConvert = _lib.lookupFunction<QtRuntimeConvertNative,
            QtRuntimeConvert>('qt_runtime_convert'),
        qtFree = _lib.lookupFunction<QtFreeNative, QtFree>('qt_free');

  // ignore: unused_field
  final DynamicLibrary _lib;

  final QtRuntimeCreate qtRuntimeCreate;
  final QtRuntimeDestroy qtRuntimeDestroy;
  final QtRuntimeConvert qtRuntimeConvert;
  final QtFree qtFree;
}
