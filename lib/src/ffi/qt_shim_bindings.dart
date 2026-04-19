// Hand-written FFI bindings to the qt_shim C library.
//
// The native surface is small (4 symbols) so hand-rolling is simpler than
// generating with ffigen + running `dart run ffigen`. If the surface grows,
// switch to ffigen by adding an `ffigen.yaml` entry pointing at
// `native/shim/qt_shim.h`.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// `int qt_init(void)` — initializes the embedded QuickJS runtime, loads
/// the bundled quicktype-core. Returns 0 on success, negative on failure.
typedef QtInitNative = Int32 Function();
typedef QtInit = int Function();

/// `char* qt_convert(const char* lang_json, const char* name_json,
///                   const char* sample_json)` — runs qtConvert in the
/// embedded runtime. All three args are pre-JSON-encoded (so caller
/// passes `"\"dart\""` not `"dart"`). Returns a `malloc`-owned UTF-8
/// string; free with [QtFree].
typedef QtConvertNative = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef QtConvert = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

/// `void qt_free(char* p)` — frees a string previously returned from
/// [QtConvert]. Using Dart's `malloc.free` on the pointer will crash — you
/// must call back into the native free.
typedef QtFreeNative = Void Function(Pointer<Utf8>);
typedef QtFree = void Function(Pointer<Utf8>);

/// `void qt_shutdown(void)` — tears down the embedded runtime.
typedef QtShutdownNative = Void Function();
typedef QtShutdown = void Function();

/// Lazily-resolved function pointers into the `qt_shim` native library.
class QtShimBindings {
  QtShimBindings(this._lib)
      : qtInit =
            _lib.lookupFunction<QtInitNative, QtInit>('qt_init'),
        qtConvert = _lib
            .lookupFunction<QtConvertNative, QtConvert>('qt_convert'),
        qtFree =
            _lib.lookupFunction<QtFreeNative, QtFree>('qt_free'),
        qtShutdown = _lib
            .lookupFunction<QtShutdownNative, QtShutdown>('qt_shutdown');

  // ignore: unused_field
  final DynamicLibrary _lib;

  final QtInit qtInit;
  final QtConvert qtConvert;
  final QtFree qtFree;
  final QtShutdown qtShutdown;
}
