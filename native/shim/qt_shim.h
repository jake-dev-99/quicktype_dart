// Public FFI surface for the quicktype_dart native bridge.
//
// Isolate/thread safety: QuickJS runtimes are single-threaded. Each Dart
// isolate must own its own runtime via qt_runtime_create(). The pointers
// returned here must not cross isolate boundaries.
//
// Lifecycle:
//   QtRuntime* rt = qt_runtime_create();           // prelude-only runtime
//   qt_runtime_load_embedded(rt);                  // OR
//   qt_runtime_load_bundle(rt, js, len);           //    load caller JS
//   char* result = qt_runtime_convert(rt, ...);    // one or more calls
//   qt_free(result);
//   qt_runtime_destroy(rt);
//
// Returned strings from qt_runtime_convert are heap-allocated — the caller
// owns them and must free via qt_free.

#ifndef QT_SHIM_H
#define QT_SHIM_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#  define QT_EXPORT __declspec(dllexport)
#else
#  define QT_EXPORT __attribute__((visibility("default")))
#endif

/// Opaque runtime handle — forward-declared here, defined in qt_shim.c.
typedef struct QtRuntime QtRuntime;

/// Creates a new runtime with just the JS prelude loaded. Call either
/// qt_runtime_load_embedded() or qt_runtime_load_bundle() before
/// qt_runtime_convert(). Returns NULL on failure.
QT_EXPORT QtRuntime* qt_runtime_create(void);

/// Loads the compiled-in quicktype-core bundle into [rt]. Returns 0 on
/// success. Returns -2 when the library was built with
/// -DQT_NO_EMBEDDED_BUNDLE (callers must use qt_runtime_load_bundle
/// instead).
QT_EXPORT int qt_runtime_load_embedded(QtRuntime* rt);

/// Loads caller-provided JS (typically a fetched quicktype-core bundle)
/// into [rt]. [js] must include any environment shims the bundle expects
/// — in practice, the concatenation of native/bundle/prelude.js +
/// native/bundle/quicktype_bundle.js. Returns 0 on success.
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
/// Returns NULL on catastrophic failure. On JS error, returns the error
/// message as a string.
QT_EXPORT char* qt_runtime_convert(QtRuntime* rt,
                                   const char* lang_json,
                                   const char* name_json,
                                   const char* sample_json,
                                   const char* options_json);

/// Frees a string previously returned from qt_runtime_convert. Safe with NULL.
QT_EXPORT void qt_free(char* p);

#ifdef __cplusplus
}
#endif

#endif  // QT_SHIM_H
