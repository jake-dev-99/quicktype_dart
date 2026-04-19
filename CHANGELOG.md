# Changelog

## 0.3.0

API-shape release — typed renderer options + web remote-bundle option —
plus a small C-side cleanup. No Dart behavior changes for callers who
stay on the existing `args:` path.

### Typed renderer options (preferred going forward)

- New `RendererOptions` base class + 22 concrete subclasses
  (`DartRendererOptions`, `KotlinRendererOptions`, `SwiftRendererOptions`,
  etc.), one per target language. Each mirrors the fields of its matching
  `*Args` class but as named constructor parameters with proper nullable
  types (`bool? useFreezed`, `CSharpFramework? framework`, …).
- `QuicktypeDart.generate` / `generateFromString` gain an
  `options: RendererOptions?` parameter:
  ```dart
  await QuicktypeDart.generate(
    label: 'User',
    data: {'id': 1, 'name': 'Jake'},
    target: TargetType.dart,
    options: const DartRendererOptions(
      useFreezed: true,
      nullSafety: true,
    ),
  );
  ```
- The old `args: Iterable<Arg>` parameter still works. When both are
  supplied, `args` overrides `options` on key collision (legacy wins to
  reduce surprise for callers mid-migration).
- All 22 `*Args` classes now carry `@Deprecated('Use *RendererOptions
  instead — removal planned for v0.4.0')`. Removal **in v0.4.0**.

### Flutter Web — remote bundle option

- New `sealed class BundleSource` with two variants:
  - `BundleSource.embedded()` — default, loads the plugin asset
    (current v0.2.1 behavior).
  - `BundleSource.remote(Uri url, {String? integrity})` — loads via a
    `<script src="…">` tag pointing at any URL. Optional Subresource
    Integrity hash for safety with third-party CDNs.
- `QuicktypeDart.setBundleSource(…)` to switch. Call before the first
  generate; Flutter Web caches the loaded bundle for the page lifetime.
- **Platform scope:** Flutter Web honors both variants. Native targets
  (macOS / iOS / Linux / Windows / Android) always use the embedded
  QuickJS bundle — remote bundle on native ships in v0.3.1 once we
  split `qt_runtime_create` into create + load phases and add a
  build-time flag to strip the embedded blob.

### Legacy FFI API removal

- The v0.2.0-dev.1…dev.6 process-global C API (`qt_init` / `qt_convert`
  / `qt_shutdown`) has been removed. The per-runtime API
  (`qt_runtime_create` / `_convert` / `_destroy`), public since
  v0.2.0-dev.7, is now the only surface. No Dart API change.

### Tooling

- `tool/gen_options.py` — parses `lib/src/models/args/lang_*.dart` and
  emits the matching `lib/src/models/options/lang_*.dart` classes. Run
  after adding a new flag to the Arg registry to keep the typed
  surface in sync. Excluded from the published tarball.

### Tests

- 41/41 pass — up from 29 (v0.2.1). Additions cover `RendererOptions`
  serialization, `BundleSource` construction + round-trip, and
  typed-vs-Arg output equivalence.

### Breaking (pre-1.0, no Dart source changes required)

- `QtShimBindings` dropped `qtInit`, `qtConvertGlobal`, `qtShutdown`
  fields — consumers that instantiated it directly (shouldn't be any)
  now have fewer fields. `QtFfiRuntime` is unchanged.
- C library exports reduced from 7 to 4 symbols. Anyone dlopen'ing the
  dylib directly is affected; Dart callers are not.

### Deferred to v0.3.1

- Native remote-bundle support.
- Binary-size reduction on native (strip the embedded 2.9MB JS when
  remote is configured).

## 0.2.1

Adds Flutter Web support via `dart:js_interop`, covering the one
platform v0.2.0 left out.

### Flutter Web transport

- `QuicktypeDart.generate` now works on Flutter Web. On non-web targets
  nothing changes: `GenerateTransport.auto` still prefers the embedded
  QuickJS FFI path; on web it routes to the new `dart:js_interop`
  backend automatically.
- `quicktype-core` ships as a plugin asset at
  `packages/quicktype_dart/assets/quicktype_bundle.js`. On first call
  the backend injects a `<script>` tag; subsequent calls go straight
  to `globalThis.qtConvert`. The same bundle powers the FFI path.
- `GenerateTransport.ffi` and `.process` throw `UnsupportedError` on
  web with clear messaging (neither `dart:ffi` nor `dart:io` is
  available in a browser).

### Architecture

- New `lib/src/backend_io.dart` (non-web) and `lib/src/backend_web.dart`
  (web) behind a conditional import in `lib/src/quicktype_dart.dart`.
  The public facade is platform-neutral; neither backend ever loads on
  the wrong target.
- Bundle shim (`native/bundle/shim.mjs`) updated to accept
  `rendererOptions` as either a JS object (FFI path) or a JSON string
  (web path, since `dart:js_interop` marshals Dart Strings as JS
  strings). Both FFI and Web now share a single bundle.

### Dependencies

- `web: ^1.1.0` added for `dart:js_interop` bindings.

### Verified

- Non-web: 29/29 tests pass, `dart analyze lib bin` clean, FFI smoke
  tests still pass with the updated bundle.
- Flutter Web: `flutter build web --release` on a scratch app consuming
  the plugin succeeds. The compiled `main.dart.js` references the
  bundle URL. The bundle ships to `build/web/assets/packages/...`.
  End-to-end bundle behaviour validated via qjs on the served bundle.

## 0.2.0

**Headline: embedded QuickJS runtime via FFI.** `QuicktypeDart.generate` now
runs quicktype-core in-process on macOS, iOS, Linux, Windows, and Android —
no Node CLI required. ~2ms per call after warmup, ~680KB of native code +
2.9MB of bundled JS added to the app.

### FFI transport

- New `GenerateTransport` enum (`auto`, `ffi`, `process`). `QuicktypeDart.generate`
  and `generateFromString` accept a `transport:` parameter. Default `auto`
  prefers the embedded FFI runtime when the native library is available,
  falls back to `Process.run` otherwise.
- `QtFfiRuntime` — per-instance handle around an embedded QuickJS runtime
  loaded with the quicktype-core bundle. Exposes `.create()` for isolated
  instances, `.instance()` for a shared lazy singleton, and `.dispose()` for
  deterministic teardown. `Finalizer` handles cleanup on GC.
- Isolate-safe: each isolate can create its own runtime; runtimes don't
  share state. Post-dispose calls throw `StateError` rather than crashing.
- Native library vendored under `native/`: trimmed quickjs-ng v0.14.0 source
  (2.5MB) + 180-line C shim + 2.9MB embedded JS bundle.

### Flutter plugin

- `pubspec.yaml` declares the package as a Flutter FFI plugin for macOS,
  iOS, Linux, Windows, and Android. Each platform uses a shared
  `native/CMakeLists.txt` as the build entry point.
- `macos/` and `ios/` ship CocoaPods podspecs that compile forwarder
  `Classes/*.c` files which `#include` from `../native/`.
- `linux/CMakeLists.txt` and `windows/CMakeLists.txt` delegate to the
  shared native tree via `add_subdirectory`, re-exporting
  `quicktype_dart_bundled_libraries` for Flutter's plugin embedding.
- `android/build.gradle` configures AGP's `externalNativeBuild` to invoke
  the same CMake; produces `libquicktype_dart.so` for arm64-v8a,
  armeabi-v7a, and x86_64.

### Arg plumbing

- Each `Arg` subclass grew a `toRendererOption()` method returning a
  `(name, stringified value)` entry that quicktype-core's `rendererOptions`
  accepts. The FFI path serializes args as a JSON object and passes it to
  quicktype alongside `lang`, `name`, and the sample.
- FFI and Process transports are feature-equivalent for args. Callers don't
  need to choose a transport based on whether they're passing `useFreezed`.

### Bundle regeneration tooling

- `native/bundle/shim.mjs` — the JS entry module bundled into
  `quicktype_bundle.js`. Exposes `globalThis.qtConvert(lang, name, json, opts)`.
- `native/bundle/build_bundle.sh` + `package.json` — run `npm install` then
  `./build_bundle.sh` to rebuild `quicktype_bundle.js` after a quicktype-core
  upgrade.
- `native/shim/embed_bundle.py` converts bundle + prelude into
  `native/shim/bundle_data.c` as C string literals.

### Platform support

| Platform | Status |
|---|---|
| macOS (arm64) | ✅ verified end-to-end in a Flutter app |
| macOS (x64) | ✅ should work (same CMake, not locally tested) |
| iOS | Podspec wired; runtime verification pending |
| Linux | CMake configured; runtime verification pending |
| Windows | CMake configured + MSVC shims in place; runtime verification pending |
| Android | NDK externalNativeBuild configured; runtime verification pending |
| Flutter Web | not supported (no FFI) |

### Breaking (pre-1.0)

- No renamed or removed public symbols vs v0.1.0.
- The new `transport:` parameter has a default of `GenerateTransport.auto`,
  which will prefer FFI over Process.run when the native library is
  available. Consumers who want the v0.1.0 behaviour can pass
  `transport: GenerateTransport.process`.

### Deferred to later releases

- **Flutter Web.** Not supported in v0.2.0 — the package imports `dart:io`,
  `dart:ffi`, and `dart:isolate`, which aren't available on web. Importing
  `package:quicktype_dart/quicktype_dart.dart` from a Flutter Web app will
  fail at compile time. Tracked for **v0.2.1**: a web transport using
  `dart:js_interop` + the bundled quicktype-core JS, behind conditional
  imports so the FFI/Process paths don't poison the web compile.
- **Bundle-as-asset** option to ship `quicktype_bundle.js` via Flutter's
  asset pipeline instead of embedding it in the binary. Would shave
  ~2.9MB off each platform binary. Tracked for v0.3.0.
- **Legacy process-global FFI API** (`qt_init` / `qt_convert` / `qt_shutdown`
  on the C side) is preserved in this release for compatibility with
  dev.1–dev.6 users. Removal planned for v0.3.0.

## 0.1.0

First public release.

### Runtime API

- Added `QuicktypeDart.generate({label, data, target, args})` — converts any
  JSON-encodable Dart value into generated source code in the chosen target
  language. Accepts any value `jsonEncode` accepts.
- Added `QuicktypeDart.generateFromString({label, json, target, args})` for
  raw JSON documents. Skips the re-encode when the caller already has JSON.
- Added `TargetType` (22 target languages: Dart, C, C++, C#, Elixir, Elm,
  Flow, Go, Haskell, Java, JavaScript, Kotlin, Objective-C, PHP, PropTypes,
  Python, Ruby, Rust, Scala 3, Smithy, Swift, TypeScript) and `SourceType`
  (json, jsonschema, graphql, typescript).
- Binary resolution: checks the bundled `tool/node_modules/.bin/quicktype`
  first (dev checkouts), then falls back to `quicktype` on `PATH`. Requires
  `npm install -g quicktype` for users installing from pub.dev.

### Build-time (build_runner) integration

- Added per-target builders registered in the package's `build.yaml`:
  `quicktype_dart:dart`, `quicktype_dart:kotlin`, `quicktype_dart:swift`,
  `quicktype_dart:typescript`. Consumer apps opt in via their own
  `build.yaml`.
- Input convention: files ending in `.qt.json` are processed. Output lands
  next to the source with the target's primary extension.
- Supports per-target `args:` configuration in `build.yaml` for language
  flags like `use-freezed: true` or `null-safety: true`.

### Config / orchestration

- `Quicktype` singleton for `quicktype.json`-driven batch generation via
  `buildCommandsFromConfig` + `executeAll`. Exposes `reset()` for tests.
- `Config` singleton with the same reset hook. Throws `ConfigException`
  when re-initialized with a different path rather than silently ignoring.
- `TypeConfig` carries per-slot args (`{"args": {"use-freezed": true}}` in
  JSON config).

### Typed arguments

- `Arg<T>` hierarchy — `SimpleArg`, `StringArg`, `BoolArg`, `EnumArg<T>`,
  `RepeatableArg`. Each emits proper `List<String>` argv (no shell
  escaping needed).
- `MainArgs` for core quicktype flags (`--src`, `--lang`, `--alphabetize-
  properties`, `--debug`, etc).
- Per-language arg classes: `CArgs`, `CppArgs`, `CSharpArgs`, `DartArgs`,
  `ElixirArgs`, `ElmArgs`, `FlowArgs`, `GoArgs`, `HaskellArgs`, `JavaArgs`,
  `JavaScriptArgs`, `KotlinArgs`, `ObjectiveCArgs`, `PHPArgs`,
  `PropTypesArgs`, `PythonArgs`, `RubyArgs`, `RustArgs`, `Scala3Args`,
  `SmithyArgs`, `SwiftArgs`, `TypeScriptArgs`. Each exposes every flag
  documented by the upstream quicktype CLI.

### Utilities

- `SchemaValidator` — JSON Schema validation via `json_schema`.
- `inferLangType<T extends TypeEnum>(candidates, path)` — resolves a type
  from a file extension, honouring multi-dot extensions like `.schema.json`.
- `Log` static facade over `dart:developer.log` with levels `off`, `shout`,
  `severe`, `warning`, `info`, `config`, `fine`, `finer`, `finest`, `all`.

### Notes

- **v0.1.0 is pure Dart.** Flutter plugin scaffolding for iOS / Android /
  macOS / Linux / Windows / Web ships in v0.2.0 alongside the planned
  QuickJS FFI path (removes the Node CLI dependency on mobile).
- Requires Dart SDK `^3.6.2`.
- Consumer needs `quicktype` CLI — install with `npm install -g quicktype`.
