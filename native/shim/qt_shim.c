// quicktype_dart native bridge.
//
// Public surface documented in qt_shim.h. The per-runtime API
// (qt_runtime_create/convert/destroy) is the primary entry point; the
// older process-global API (qt_init/qt_convert) is preserved as a shim on
// top of a shared global runtime for backward compatibility.

#include "qt_shim.h"
#include "quickjs.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// --- Portability shims ---------------------------------------------------

#if defined(_WIN32)
#  define strdup _strdup

static int asprintf(char** strp, const char* fmt, ...) {
  if (!strp) return -1;
  va_list args;
  va_start(args, fmt);
  int len = _vscprintf(fmt, args);
  va_end(args);
  if (len < 0) return -1;
  char* buf = (char*)malloc((size_t)len + 1);
  if (!buf) return -1;
  va_start(args, fmt);
  int written = vsnprintf(buf, (size_t)len + 1, fmt, args);
  va_end(args);
  if (written < 0) { free(buf); return -1; }
  *strp = buf;
  return written;
}
#endif

// Embedded by embed_bundle.py at build time.
extern const unsigned char qt_prelude_js[];
extern const unsigned long qt_prelude_js_len;
extern const unsigned char qt_bundle_js[];
extern const unsigned long qt_bundle_js_len;

// --- Opaque runtime handle -----------------------------------------------

struct QtRuntime {
  JSRuntime* rt;
  JSContext* ctx;
};

// Pump QuickJS's pending job queue until drained.
static void pump(JSContext* ctx) {
  JSContext* cctx = NULL;
  const int MAX = 1000000;
  for (int i = 0; i < MAX; i++) {
    int ret = JS_ExecutePendingJob(JS_GetRuntime(ctx), &cctx);
    if (ret <= 0) return;
  }
}

static int load_sources(JSContext* ctx) {
  JSValue r = JS_Eval(ctx, (const char*)qt_prelude_js, qt_prelude_js_len,
                      "<prelude>", JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(r)) {
    JSValue e = JS_GetException(ctx);
    const char* msg = JS_ToCString(ctx, e);
    fprintf(stderr, "qt_shim: prelude error: %s\n", msg ? msg : "?");
    JS_FreeCString(ctx, msg);
    JS_FreeValue(ctx, e);
    JS_FreeValue(ctx, r);
    return -1;
  }
  JS_FreeValue(ctx, r);

  r = JS_Eval(ctx, (const char*)qt_bundle_js, qt_bundle_js_len,
              "<bundle>", JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(r)) {
    JSValue e = JS_GetException(ctx);
    const char* msg = JS_ToCString(ctx, e);
    fprintf(stderr, "qt_shim: bundle error: %s\n", msg ? msg : "?");
    JS_FreeCString(ctx, msg);
    JS_FreeValue(ctx, e);
    JS_FreeValue(ctx, r);
    return -2;
  }
  JS_FreeValue(ctx, r);
  return 0;
}

QT_EXPORT QtRuntime* qt_runtime_create(void) {
  QtRuntime* handle = (QtRuntime*)calloc(1, sizeof(QtRuntime));
  if (!handle) return NULL;

  handle->rt = JS_NewRuntime();
  if (!handle->rt) { free(handle); return NULL; }
  handle->ctx = JS_NewContext(handle->rt);
  if (!handle->ctx) {
    JS_FreeRuntime(handle->rt);
    free(handle);
    return NULL;
  }

  if (load_sources(handle->ctx) != 0) {
    JS_FreeContext(handle->ctx);
    JS_FreeRuntime(handle->rt);
    free(handle);
    return NULL;
  }

  return handle;
}

QT_EXPORT void qt_runtime_destroy(QtRuntime* rt) {
  if (!rt) return;
  if (rt->ctx) JS_FreeContext(rt->ctx);
  if (rt->rt)  JS_FreeRuntime(rt->rt);
  free(rt);
}

QT_EXPORT char* qt_runtime_convert(QtRuntime* rt,
                                   const char* lang_json,
                                   const char* name_json,
                                   const char* sample_json,
                                   const char* options_json) {
  if (!rt || !rt->ctx) return NULL;
  JSContext* ctx = rt->ctx;

  JSValue global = JS_GetGlobalObject(ctx);
  JS_SetPropertyStr(ctx, global, "__qtResult", JS_NULL);
  JS_SetPropertyStr(ctx, global, "__qtError", JS_NULL);
  JS_FreeValue(ctx, global);

  const char* opts = (options_json && *options_json) ? options_json : "{}";

  char* invoker = NULL;
  if (asprintf(&invoker,
      "(async () => {"
      "  try {"
      "    globalThis.__qtResult = await globalThis.qtConvert(%s, %s, %s, %s);"
      "  } catch (e) {"
      "    globalThis.__qtError = (e && e.message) || String(e);"
      "  }"
      "})();",
      lang_json, name_json, sample_json, opts) < 0) {
    return NULL;
  }

  JSValue r = JS_Eval(ctx, invoker, strlen(invoker),
                      "<invoker>", JS_EVAL_TYPE_GLOBAL);
  free(invoker);
  if (JS_IsException(r)) {
    JSValue e = JS_GetException(ctx);
    const char* msg = JS_ToCString(ctx, e);
    char* copy = msg ? strdup(msg) : NULL;
    JS_FreeCString(ctx, msg);
    JS_FreeValue(ctx, e);
    JS_FreeValue(ctx, r);
    return copy;
  }
  JS_FreeValue(ctx, r);

  pump(ctx);

  global = JS_GetGlobalObject(ctx);
  JSValue err = JS_GetPropertyStr(ctx, global, "__qtError");
  if (!JS_IsNull(err) && !JS_IsUndefined(err)) {
    const char* s = JS_ToCString(ctx, err);
    char* copy = s ? strdup(s) : NULL;
    JS_FreeCString(ctx, s);
    JS_FreeValue(ctx, err);
    JS_FreeValue(ctx, global);
    return copy;
  }
  JS_FreeValue(ctx, err);

  JSValue result = JS_GetPropertyStr(ctx, global, "__qtResult");
  const char* s = JS_ToCString(ctx, result);
  char* copy = s ? strdup(s) : NULL;
  JS_FreeCString(ctx, s);
  JS_FreeValue(ctx, result);
  JS_FreeValue(ctx, global);
  return copy;
}

QT_EXPORT void qt_free(char* p) {
  if (p) free(p);
}

// --- Legacy process-global API -------------------------------------------

static QtRuntime* g_legacy = NULL;

QT_EXPORT int qt_init(void) {
  if (g_legacy) return 0;
  g_legacy = qt_runtime_create();
  return g_legacy ? 0 : -1;
}

QT_EXPORT char* qt_convert(const char* lang_json,
                           const char* name_json,
                           const char* sample_json,
                           const char* options_json) {
  if (!g_legacy && qt_init() != 0) return NULL;
  return qt_runtime_convert(g_legacy, lang_json, name_json,
                            sample_json, options_json);
}

QT_EXPORT void qt_shutdown(void) {
  if (g_legacy) { qt_runtime_destroy(g_legacy); g_legacy = NULL; }
}
