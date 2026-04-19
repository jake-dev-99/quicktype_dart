// SPDX-License-Identifier: MIT
// Copyright (c) 2024 Jake Allen and quicktype_dart contributors.
//
// Public FFI surface for the quicktype_dart native bridge.
//
// ============================================================================
//  Lifecycle
// ============================================================================
//
//   QtRuntime* rt = qt_runtime_create();           // prelude-only runtime
//   qt_runtime_load_embedded(rt);                  // ... OR
//   qt_runtime_load_bundle(rt, js, len);           //     load caller JS
//   char* result = qt_runtime_convert(rt, ...);    // one or more calls
//   qt_free(result);
//   qt_runtime_destroy(rt);
//
// Returned strings from qt_runtime_convert are heap-allocated — the caller
// owns them and must free via qt_free.
//
// ============================================================================
//  Thread safety
// ============================================================================
//
// QuickJS runtimes are single-threaded. The contract:
//
//   * Each OS thread (and in practice, each Dart isolate) must own its own
//     QtRuntime. Concurrent calls on the SAME handle from different threads
//     are undefined behavior.
//   * Concurrent calls on DIFFERENT handles are safe — there is no shared
//     mutable state between runtimes.
//   * qt_runtime_destroy() must be called from the same thread that created
//     the runtime, and is safe to call with NULL.
//   * qt_free() is thread-safe and safe to call with NULL.
//
// ============================================================================
//  Return codes
// ============================================================================
//
// The qt_runtime_load_* and qt_runtime_convert functions share this
// convention:
//
//    0   success.
//   -1   invalid argument (NULL runtime, NULL required pointer, etc.) —
//        the call made no observable changes to the runtime.
//   -2   feature unavailable — currently only qt_runtime_load_embedded
//        when the library was built with -DQT_NO_EMBEDDED_BUNDLE.
//
// Any other negative value indicates a QuickJS-level evaluation error;
// the runtime is left in an unspecified state and should be destroyed.
// qt_runtime_convert additionally returns NULL on catastrophic failure
// and an error-message string on JS-level exceptions (see below).

#ifndef QT_SHIM_H
#define QT_SHIM_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#  define QT_EXPORT __declspec(dllexport)
#elif defined(__has_attribute)
#  if __has_attribute(visibility)
#    define QT_EXPORT __attribute__((visibility("default")))
#  else
#    define QT_EXPORT
#  endif
#else
#  define QT_EXPORT
#endif

/// Opaque runtime handle — forward-declared here, defined in qt_shim.c.
typedef struct QtRuntime QtRuntime;

/// Creates a new runtime with just the JS prelude loaded. Call either
/// qt_runtime_load_embedded() or qt_runtime_load_bundle() before
/// qt_runtime_convert(). Returns NULL on failure.
QT_EXPORT QtRuntime* qt_runtime_create(void);

/// Loads the compiled-in quicktype-core bundle into [rt].
/// Returns 0 on success, -1 on invalid argument, -2 when the library was
/// built with -DQT_NO_EMBEDDED_BUNDLE (callers must use
/// qt_runtime_load_bundle instead).
QT_EXPORT int qt_runtime_load_embedded(QtRuntime* rt);

/// Loads caller-provided JS (typically a fetched quicktype-core bundle)
/// into [rt]. [js] must include any environment shims the bundle expects
/// — in practice, the concatenation of native/bundle/prelude.js +
/// native/bundle/quicktype_bundle.js.
/// Returns 0 on success, -1 on invalid argument.
QT_EXPORT int qt_runtime_load_bundle(QtRuntime* rt, const char* js,
                                     size_t len);

/// Tears down a runtime previously returned from qt_runtime_create.
/// Safe to call with NULL.
QT_EXPORT void qt_runtime_destroy(QtRuntime* rt);

/// Runs qtConvert in the given runtime.
///
/// All four arguments are **JSON-encoded** so they can be interpolated
/// verbatim into the JS invoker:
///
///   lang_json      — e.g. `"dart"`
///   name_json      — e.g. `"User"`
///   sample_json    — e.g. `"{\"id\":1}"`
///   options_json   — an object `{"use-freezed": "true", ...}`; pass
///                    `NULL` or `"{}"` for no options.
///
/// Returns a heap-allocated UTF-8 string the caller must free via qt_free.
/// Returns NULL on catastrophic failure. On JS-level exceptions, returns
/// the error message as a string (also freed via qt_free).
QT_EXPORT char* qt_runtime_convert(QtRuntime* rt,
                                   const char* lang_json,
                                   const char* name_json,
                                   const char* sample_json,
                                   const char* options_json);

/// Frees a string previously returned from qt_runtime_convert.
/// Safe to call with NULL. Thread-safe.
QT_EXPORT void qt_free(char* p);

#ifdef __cplusplus
}
#endif

#endif  // QT_SHIM_H
