// SPDX-License-Identifier: MIT
// Copyright (c) 2024 Jake Allen and quicktype_dart contributors.
//
// quicktype_dart native bridge.
//
// Public surface documented in qt_shim.h. Each caller creates its own
// opaque runtime handle via qt_runtime_create() — empty, with just the
// prelude loaded — then calls either qt_runtime_load_embedded() or
// qt_runtime_load_bundle() before qt_runtime_convert().
//
// QuickJS is single-threaded, so one handle per Dart isolate keeps
// things race-free.

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

// Embedded by embed_bundle.py at build time. When the library is built
// with -DQT_NO_EMBEDDED_BUNDLE, bundle_data.c is NOT compiled in, the
// symbols are undefined, and qt_runtime_load_embedded returns -1.
#ifndef QT_NO_EMBEDDED_BUNDLE
extern const unsigned char qt_prelude_js[];
extern const unsigned long qt_prelude_js_len;
extern const unsigned char qt_bundle_js[];
extern const unsigned long qt_bundle_js_len;
#endif

// --- Opaque runtime handle -----------------------------------------------

struct QtRuntime {
  JSRuntime* rt;
  JSContext* ctx;
};

// Drain QuickJS's pending job queue until empty or the hard cap is hit.
//
// qt_runtime_convert schedules an async IIFE that resolves into a global
// slot; the result isn't visible until the microtask queue fully drains.
// JS_ExecutePendingJob returns 1 when it ran a job, 0 when the queue was
// already empty, or a negative value on error. We loop until the queue
// is empty (non-positive return) or the guard trips.
//
// The 1,000,000-iteration cap is a tripwire against pathological input —
// a promise chain that never terminates — not a production limit.
// quicktype-core's normal generation path drains in a few thousand jobs
// for even large inputs.
static void pump(JSContext* ctx) {
  JSContext* cctx = NULL;
  const int MAX = 1000000;
  for (int i = 0; i < MAX; i++) {
    int ret = JS_ExecutePendingJob(JS_GetRuntime(ctx), &cctx);
    if (ret <= 0) return;
  }
}

// Evaluates a JS source chunk under a given filename tag. Returns 0 on
// success, or a negative error code — stderr gets a diagnostic when it
// fails.
static int eval_js(JSContext* ctx, const char* js, size_t len,
                   const char* filename) {
  JSValue r = JS_Eval(ctx, js, len, filename, JS_EVAL_TYPE_GLOBAL);
  if (JS_IsException(r)) {
    JSValue e = JS_GetException(ctx);
    const char* msg = JS_ToCString(ctx, e);
    fprintf(stderr, "qt_shim: %s error: %s\n", filename, msg ? msg : "?");
    JS_FreeCString(ctx, msg);
    JS_FreeValue(ctx, e);
    JS_FreeValue(ctx, r);
    return -1;
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

  // Load the prelude (small, always embedded even when QT_NO_EMBEDDED_BUNDLE
  // is set — it's needed for any quicktype-core bundle to run). When the
  // prelude isn't embedded either, the caller is responsible for loading
  // equivalent environment shims via qt_runtime_load_bundle.
#ifndef QT_NO_EMBEDDED_BUNDLE
  if (eval_js(handle->ctx, (const char*)qt_prelude_js, qt_prelude_js_len,
              "<prelude>") != 0) {
    JS_FreeContext(handle->ctx);
    JS_FreeRuntime(handle->rt);
    free(handle);
    return NULL;
  }
#endif

  return handle;
}

QT_EXPORT int qt_runtime_load_embedded(QtRuntime* rt) {
  if (!rt || !rt->ctx) return -1;
#ifdef QT_NO_EMBEDDED_BUNDLE
  fprintf(stderr, "qt_shim: qt_runtime_load_embedded called but the library "
                  "was built with QT_NO_EMBEDDED_BUNDLE. Use "
                  "qt_runtime_load_bundle with caller-provided JS instead.\n");
  return -2;
#else
  return eval_js(rt->ctx, (const char*)qt_bundle_js, qt_bundle_js_len,
                 "<bundle>");
#endif
}

QT_EXPORT int qt_runtime_load_bundle(QtRuntime* rt, const char* js,
                                     size_t len) {
  if (!rt || !rt->ctx || !js) return -1;
  // When QT_NO_EMBEDDED_BUNDLE is set the prelude wasn't loaded in
  // qt_runtime_create. The caller's `js` is expected to be a
  // prelude-plus-bundle concatenation (see native/bundle/prelude.js
  // for the shims required).
  return eval_js(rt->ctx, js, len, "<bundle>");
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
