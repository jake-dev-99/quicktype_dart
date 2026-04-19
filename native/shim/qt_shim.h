// Public FFI surface for the quicktype_dart native bridge.
//
// Isolate/thread safety: QuickJS runtimes are single-threaded. To run from
// multiple Dart isolates concurrently, each isolate must own its own
// runtime via `qt_runtime_create()` / `qt_runtime_destroy()`. The pointers
// returned here must not cross isolate boundaries.
//
// Returned strings from qt_runtime_convert are heap-allocated — the caller
// owns them and must free via qt_free.

#ifndef QT_SHIM_H
#define QT_SHIM_H

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

/// Creates a new runtime (JSRuntime + JSContext) and loads the embedded
/// quicktype-core bundle + prelude. Returns NULL on failure.
QT_EXPORT QtRuntime* qt_runtime_create(void);

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

// --- Legacy process-global API (deprecated) ------------------------------
// Retained for backward compatibility with v0.2.0-dev.1..dev.6. New code
// should use the per-runtime API above. These will be removed in v0.3.0.

QT_EXPORT int   qt_init(void);
QT_EXPORT char* qt_convert(const char* lang_json,
                           const char* name_json,
                           const char* sample_json,
                           const char* options_json);
QT_EXPORT void  qt_shutdown(void);

#ifdef __cplusplus
}
#endif

#endif  // QT_SHIM_H
