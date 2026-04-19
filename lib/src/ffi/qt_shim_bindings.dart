// Hand-written FFI bindings to the qt_shim C library.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// `QtRuntime* qt_runtime_create(void)` — creates a runtime with only the
/// prelude loaded. Call [QtRuntimeLoadEmbedded] or [QtRuntimeLoadBundle]
/// before [QtRuntimeConvert]. Returns `nullptr` on failure.
typedef QtRuntimeCreateNative = Pointer<Void> Function();
typedef QtRuntimeCreate = Pointer<Void> Function();

/// `int qt_runtime_load_embedded(QtRuntime*)` — loads the compiled-in
/// quicktype-core bundle. Returns 0 on success, -2 if the library was
/// built with `-DQT_NO_EMBEDDED_BUNDLE`.
typedef QtRuntimeLoadEmbeddedNative = Int32 Function(Pointer<Void>);
typedef QtRuntimeLoadEmbedded = int Function(Pointer<Void>);

/// `int qt_runtime_load_bundle(QtRuntime*, const char* js, size_t len)` —
/// loads caller-supplied JS into the runtime. Returns 0 on success.
///
/// Note: the `len` argument is `size_t` on the C side but `int` here.
/// On every platform Dart supports, `int` is 64-bit so the effective
/// cap is ~9 EB — orders of magnitude beyond any quicktype-core bundle
/// we'd ever hand over. On a hypothetical 32-bit target, `int` is still
/// 64-bit in Dart, so there is no silent narrowing at the language
/// level; the only risk is the C `size_t` being 32-bit, which would
/// cap bundles at ~4 GB. The compiled quicktype bundle is ~3 MB.
typedef QtRuntimeLoadBundleNative = Int32 Function(
    Pointer<Void>, Pointer<Utf8>, Size);
typedef QtRuntimeLoadBundle = int Function(Pointer<Void>, Pointer<Utf8>, int);

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
      : qtRuntimeCreate =
            _lib.lookupFunction<QtRuntimeCreateNative, QtRuntimeCreate>(
                'qt_runtime_create'),
        qtRuntimeLoadEmbedded = _lib.lookupFunction<QtRuntimeLoadEmbeddedNative,
            QtRuntimeLoadEmbedded>('qt_runtime_load_embedded'),
        qtRuntimeLoadBundle =
            _lib.lookupFunction<QtRuntimeLoadBundleNative, QtRuntimeLoadBundle>(
                'qt_runtime_load_bundle'),
        qtRuntimeDestroy =
            _lib.lookupFunction<QtRuntimeDestroyNative, QtRuntimeDestroy>(
                'qt_runtime_destroy'),
        qtRuntimeConvert =
            _lib.lookupFunction<QtRuntimeConvertNative, QtRuntimeConvert>(
                'qt_runtime_convert'),
        qtFree = _lib.lookupFunction<QtFreeNative, QtFree>('qt_free');

  // ignore: unused_field
  final DynamicLibrary _lib;

  final QtRuntimeCreate qtRuntimeCreate;
  final QtRuntimeLoadEmbedded qtRuntimeLoadEmbedded;
  final QtRuntimeLoadBundle qtRuntimeLoadBundle;
  final QtRuntimeDestroy qtRuntimeDestroy;
  final QtRuntimeConvert qtRuntimeConvert;
  final QtFree qtFree;
}
