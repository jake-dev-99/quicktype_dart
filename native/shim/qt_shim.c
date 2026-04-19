// quicktype_dart native bridge.
//
// Exposes a minimal C surface for Dart FFI:
//
//   int   qt_init(void)
//     Lazily initializes the QuickJS runtime, loads the embedded
//     quicktype-core bundle + prelude, and returns 0 on success. Safe to
//     call multiple times.
//
//   char* qt_convert(const char* lang_json,
//                    const char* name_json,
//                    const char* sample_json)
//     Runs qtConvert(lang, name, sample) in the embedded runtime. All three
//     arguments are JSON-encoded strings (use jsonEncode on the Dart side).
//     Returns a heap-allocated UTF-8 string the caller must free with
//     qt_free(). Returns NULL on catastrophic failure; otherwise either
//     the generated source or a JS error string is returned.
//
//   void  qt_free(char* p)
//     Frees a string returned from qt_convert.
//
//   void  qt_shutdown(void)
//     Tears down the runtime. Subsequent qt_convert calls will re-init.
//
// The embedded bundle + prelude are C arrays generated at build time from
// native/bundle/*.js — see native/shim/embed_bundle.py.

#include "qt_shim.h"
#include "quickjs.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Generated at build time by embed_bundle.py.
extern const char qt_prelude_js[];
extern const unsigned long qt_prelude_js_len;
extern const char qt_bundle_js[];
extern const unsigned long qt_bundle_js_len;

static JSRuntime* g_rt = NULL;
static JSContext* g_ctx = NULL;
static int g_initialized = 0;

// Pump QuickJS's pending job queue until drained or we've spun too many times.
static void pump(JSContext* ctx) {
  JSContext* cctx = NULL;
  int iter = 0;
  const int MAX = 1000000;
  while (iter++ < MAX) {
    int ret = JS_ExecutePendingJob(JS_GetRuntime(ctx), &cctx);
    if (ret <= 0) return;
  }
}

QT_EXPORT int qt_init(void) {
  if (g_initialized) return 0;

  g_rt = JS_NewRuntime();
  if (!g_rt) return -1;
  g_ctx = JS_NewContext(g_rt);
  if (!g_ctx) {
    JS_FreeRuntime(g_rt);
    g_rt = NULL;
    return -2;
  }

  JSValue r = JS_Eval(g_ctx, qt_prelude_js, qt_prelude_js_len,
                      "<prelude>", JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(r)) {
    JSValue e = JS_GetException(g_ctx);
    const char* msg = JS_ToCString(g_ctx, e);
    fprintf(stderr, "qt_shim: prelude error: %s\n", msg ? msg : "?");
    JS_FreeCString(g_ctx, msg);
    JS_FreeValue(g_ctx, e);
    JS_FreeValue(g_ctx, r);
    JS_FreeContext(g_ctx);
    JS_FreeRuntime(g_rt);
    g_ctx = NULL; g_rt = NULL;
    return -3;
  }
  JS_FreeValue(g_ctx, r);

  r = JS_Eval(g_ctx, qt_bundle_js, qt_bundle_js_len,
              "<bundle>", JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(r)) {
    JSValue e = JS_GetException(g_ctx);
    const char* msg = JS_ToCString(g_ctx, e);
    fprintf(stderr, "qt_shim: bundle error: %s\n", msg ? msg : "?");
    JS_FreeCString(g_ctx, msg);
    JS_FreeValue(g_ctx, e);
    JS_FreeValue(g_ctx, r);
    JS_FreeContext(g_ctx);
    JS_FreeRuntime(g_rt);
    g_ctx = NULL; g_rt = NULL;
    return -4;
  }
  JS_FreeValue(g_ctx, r);

  g_initialized = 1;
  return 0;
}

QT_EXPORT char* qt_convert(const char* lang_json,
                           const char* name_json,
                           const char* sample_json) {
  if (!g_initialized && qt_init() != 0) return NULL;

  JSValue global = JS_GetGlobalObject(g_ctx);
  JS_SetPropertyStr(g_ctx, global, "__qtResult", JS_NULL);
  JS_SetPropertyStr(g_ctx, global, "__qtError", JS_NULL);
  JS_FreeValue(g_ctx, global);

  // Build the async invoker. Each JSON arg is a pre-escaped JS string literal.
  char* invoker = NULL;
  if (asprintf(&invoker,
      "(async () => {"
      "  try {"
      "    globalThis.__qtResult = await globalThis.qtConvert(%s, %s, %s);"
      "  } catch (e) {"
      "    globalThis.__qtError = (e && e.message) || String(e);"
      "  }"
      "})();",
      lang_json, name_json, sample_json) < 0) {
    return NULL;
  }

  JSValue r = JS_Eval(g_ctx, invoker, strlen(invoker),
                      "<invoker>", JS_EVAL_TYPE_GLOBAL);
  free(invoker);
  if (JS_IsException(r)) {
    JSValue e = JS_GetException(g_ctx);
    const char* s = JS_ToCString(g_ctx, e);
    char* copy = s ? strdup(s) : NULL;
    JS_FreeCString(g_ctx, s);
    JS_FreeValue(g_ctx, e);
    JS_FreeValue(g_ctx, r);
    return copy;
  }
  JS_FreeValue(g_ctx, r);

  // Drain the promise queue.
  pump(g_ctx);

  // Read __qtError or __qtResult.
  global = JS_GetGlobalObject(g_ctx);
  JSValue err = JS_GetPropertyStr(g_ctx, global, "__qtError");
  if (!JS_IsNull(err) && !JS_IsUndefined(err)) {
    const char* s = JS_ToCString(g_ctx, err);
    char* copy = s ? strdup(s) : NULL;
    JS_FreeCString(g_ctx, s);
    JS_FreeValue(g_ctx, err);
    JS_FreeValue(g_ctx, global);
    return copy;
  }
  JS_FreeValue(g_ctx, err);

  JSValue result = JS_GetPropertyStr(g_ctx, global, "__qtResult");
  const char* s = JS_ToCString(g_ctx, result);
  char* copy = s ? strdup(s) : NULL;
  JS_FreeCString(g_ctx, s);
  JS_FreeValue(g_ctx, result);
  JS_FreeValue(g_ctx, global);
  return copy;
}

QT_EXPORT void qt_free(char* p) {
  if (p) free(p);
}

QT_EXPORT void qt_shutdown(void) {
  if (g_ctx) { JS_FreeContext(g_ctx); g_ctx = NULL; }
  if (g_rt)  { JS_FreeRuntime(g_rt);  g_rt = NULL; }
  g_initialized = 0;
}
