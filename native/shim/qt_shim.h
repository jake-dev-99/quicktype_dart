// Public FFI surface for the quicktype_dart native bridge.
//
// Everything here is exported with C linkage and a `qt_` prefix. Returned
// strings from qt_convert are heap-allocated — the caller owns them and
// must free via qt_free.

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

QT_EXPORT int   qt_init(void);
QT_EXPORT char* qt_convert(const char* lang_json,
                           const char* name_json,
                           const char* sample_json);
QT_EXPORT void  qt_free(char* p);
QT_EXPORT void  qt_shutdown(void);

#ifdef __cplusplus
}
#endif

#endif  // QT_SHIM_H
