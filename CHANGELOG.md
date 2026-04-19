# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
conventions. Until v1.0.0, breaking changes may land on minor-version
bumps — they're always flagged explicitly under **Removed** or
**Breaking**.

## 0.4.3

CI, native polish, and per-field documentation. Final release in the
0.4.x RC cycle.

### Added

- `.github/workflows/ci.yml` — runs `dart analyze --fatal-infos` and
  `dart test --exclude-tags integration` on every push to Master and
  every PR.
- `.github/workflows/build.yml` — cross-platform native build matrix
  (ubuntu-latest + macos-latest) that exercises `cmake --build` with
  both the default embedded bundle and `-DQT_EMBED_BUNDLE=OFF`, plus
  the `ffi_smoke` / `ffi_isolate_smoke` / `ffi_remote_smoke` scripts
  against the freshly-built shared library.
- `native/README.md` — architecture and regeneration guide for
  contributors touching the C side.
- Per-field `///` dartdoc on every `*RendererOptions` field — e.g.
  `DartRendererOptions.useFreezed` now carries `Maps to the
  --use-freezed flag.`, giving IDE hover and `dart doc` output the
  authoritative CLI-flag mapping.
- SPDX headers on `native/shim/qt_shim.h` and `native/shim/qt_shim.c`,
  and a self-contained thread-safety / return-code contract block in
  the public header.

### Changed

- `QT_EXPORT` macro in `native/shim/qt_shim.h` uses
  `__has_attribute(visibility)` to gracefully fall through on
  compilers that lack the attribute (Windows, TinyCC, etc.).
- `native/CMakeLists.txt` sets `VERSION`/`SOVERSION` on the
  `quicktype_dart` target (matters for standalone Linux consumers; a
  no-op on macOS/iOS/Windows).
- Warning-suppression flags consolidated to the shim target in CMake;
  podspec `OTHER_CFLAGS` lines trimmed to just the two upstream
  quickjs-ng warnings not covered by the compile target options.
- iOS deployment target bumped from 12.0 → 13.0.
- macOS deployment target bumped from 10.14 → 10.15.
- `pump()` in `qt_shim.c` gained a comment explaining the
  1,000,000-iteration safety cap.

## 0.4.2

Documentation-polish release. Zero public API changes; README, CHANGELOG,
and pubspec metadata rewritten for the first release-candidate cycle.

### Changed

- README rewritten end-to-end: platform support matrix, copy-paste
  quickstart, typed-options walkthrough, bundle-source guidance,
  migration guide from 0.3.x, FAQ, attribution section, full-glossary
  first-use definitions for FFI / QuickJS / Subresource Integrity.
- `pubspec.yaml` `homepage:` points at the GitHub repo instead of the
  orphaned `simplezen.io` URL.
- CHANGELOG reformatted to [Keep a Changelog] sections
  (`### Added` / `### Changed` / `### Deprecated` / `### Removed` /
  `### Fixed`) across all entries, with explicit **Breaking** callouts
  on applicable releases.

### Added

- Attribution section in the README crediting `quicktype-core`
  (Apache 2.0) and `QuickJS-NG` (MIT).
- FAQ covering the most common pre-adoption questions (binary size,
  offline operation, engine choice, testability).

## 0.4.1

Housekeeping release: license swap, tooling cleanup, and style-guide
alignment. No public-API changes.

### Changed

- License changed from Apache 2.0 → MIT. The README and podspecs are
  updated to match; the LICENSE file in the tarball is authoritative.
- CLI `--version` now reads from a new `lib/src/version.dart` constant
  (`packageVersion`) instead of a hardcoded string, eliminating version
  drift between pubspec and the CLI.
- Help text URL in the CLI (`dart run quicktype_dart --help`) now points
  at the real GitHub repo rather than a placeholder.
- `lib/src/utils/file_resolver.dart` rewritten for Dart style: imports
  ordered (`dart:` → `package:` → relative), JSDoc-style `@param`
  blocks replaced with dartdoc, and the `path` prefix normalized.

### Fixed

- `.pubignore` brought up to date: adds `bin/ffi_remote_smoke.dart` and
  `bin/ffi_noembed_smoke.dart` (added in v0.3.1 but missed from the
  ignore list); removes stale references to files that no longer exist
  (`bin/ffi_args_smoke.dart`, `bin/options_smoke.dart`,
  `tool/gen_options.py`).
- Every non-part Dart file under `lib/` now carries an explicit
  `library;` directive, per the Dart 3 style guide.

## 0.4.0

**Breaking-change release.** Removes the `*Args` surface deprecated in v0.3.0
and converges on typed `*RendererOptions` as the single public API for
language-specific flags.

### Removed — breaking

- Deleted all 22 `*Args` classes (`DartArgs`, `KotlinArgs`, …) and their
  base types (`Arg`, `SimpleArg`, `BoolArg`, `StringArg`, `EnumArg`,
  `RepeatableArg`, `MainArgs`). Replace with the matching
  `*RendererOptions` class — e.g. `DartArgs.useFreezed..value = true` →
  `DartRendererOptions(useFreezed: true)`.
- Removed the `args:` parameter from `QuicktypeDart.generate` and
  `QuicktypeDart.generateFromString`. Pass a `RendererOptions` subclass
  via `options:` instead.
- `TypeConfig.args` (`List<Arg>`) is now `TypeConfig.rendererOptions`
  (`Map<String, String>`). The `quicktype.json` `args:` block still
  parses, but values round-trip as strings rather than typed `Arg`
  instances.
- `QuicktypeCommand.args` is now `QuicktypeCommand.rendererOptions`
  (`Map<String, String>`).
- `TypeEnum.args` getter removed. Callers doing arg-key validation
  against the registry should check `quicktype-core`'s own docs or the
  corresponding `*RendererOptions` field names.
- `tool/gen_options.py` deleted — the typed `*RendererOptions` classes
  are the source of truth going forward; edit them directly when adding
  fields.

### Changed

- Enum types previously under `lib/src/models/args/enums.dart` moved to
  `lib/src/models/enums.dart`. Re-exported from the main barrel, so most
  consumers don't need to update imports.

### Fixed

- Resolved three stale `TODO` comments in `lib/src/quicktype.dart`.

### Migration

```dart
// before (v0.3.x)
await QuicktypeDart.generate(
  label: 'User',
  data: data,
  target: TargetType.dart,
  args: [DartArgs.useFreezed..value = true, DartArgs.nullSafety..value = true],
);

// after (v0.4.0)
await QuicktypeDart.generate(
  label: 'User',
  data: data,
  target: TargetType.dart,
  options: const DartRendererOptions(useFreezed: true, nullSafety: true),
);
```

## 0.3.1

Native remote-bundle parity + opt-out embedding. Finishes the
remote-bundle story started in v0.3.0, where only Flutter Web honored
`BundleSource.remote`. Apps that lean on remote bundles now have a path
to ~2.9MB native-binary savings.

### Added

- Native `BundleSource.remote(Uri, {integrity})` — macOS / iOS / Linux /
  Windows / Android fetch the JS via `HttpClient`, cache it under the
  system temp dir keyed by URL hash, and verify an optional
  Subresource-Integrity token (`sha256-…`, `sha384-…`, `sha512-…`) before
  loading it into QuickJS. `file://` URLs supported for tests.
- CMake option `QT_EMBED_BUNDLE` (default `ON`). `-DQT_EMBED_BUNDLE=OFF`
  skips the embedded bundle; `libquicktype_dart.dylib` goes from **~4.0MB
  → ~1.1MB** on macOS.
- `qt_runtime_load_embedded(QtRuntime*)` and
  `qt_runtime_load_bundle(QtRuntime*, const char*, size_t)` C entry
  points, splitting the bundle-load phase out of `qt_runtime_create`.
- `test/native_bundle_cache_test.dart` covers sha256/384/512 integrity
  matching, mismatch rejection, and malformed tokens.
- `bin/ffi_remote_smoke.dart` and `bin/ffi_noembed_smoke.dart` exercise
  the remote and no-embed paths end-to-end.
- `crypto: ^3.0.0` dependency, for on-disk SRI verification.

### Changed

- `QuicktypeDart.setBundleSource(…)` now affects native targets as well
  as Flutter Web.
- `qt_runtime_create` now loads only the prelude; callers must invoke
  `qt_runtime_load_embedded` or `qt_runtime_load_bundle` before
  `qt_runtime_convert`. `QtFfiRuntime.create()` does this automatically.

### No breaking changes

- Default behavior unchanged: embedded bundle still used unless
  `BundleSource.remote(…)` is configured.
- On macOS / iOS (CocoaPods), the embedded bundle ships by default;
  strip it by defining `QT_NO_EMBEDDED_BUNDLE` in `OTHER_CFLAGS` and
  removing `Classes/bundle_data.c`.

## 0.3.0

API-shape release — typed renderer options and web remote-bundle
support — plus legacy C-API cleanup. No Dart behavior changes for
callers already on the `args:` path (deprecated here, removed in v0.4.0).

### Added

- `RendererOptions` base class + 22 concrete `*RendererOptions`
  subclasses (`DartRendererOptions`, `KotlinRendererOptions`,
  `SwiftRendererOptions`, …), one per target language. Each exposes
  every renderer flag as a named constructor parameter with proper
  nullable types.
- `options: RendererOptions?` parameter on `QuicktypeDart.generate` and
  `generateFromString`.
- `sealed class BundleSource` with `BundleSource.embedded()` (default)
  and `BundleSource.remote(Uri, {integrity})`. Flutter Web honors both;
  native always uses embedded in v0.3.0 (remote parity lands in v0.3.1).
- `QuicktypeDart.setBundleSource(…)` for switching before the first
  generate.
- `tool/gen_options.py` — dev-only scaffolding that parsed the
  `*Args` classes to emit the matching `*RendererOptions` classes.
  Removed in v0.4.0 once the generated classes became the source of
  truth.

### Deprecated

- All 22 `*Args` classes (`DartArgs`, `KotlinArgs`, etc.) annotated with
  `@Deprecated('Use *RendererOptions — removal planned for v0.4.0')`.

### Removed

- Process-global C FFI (`qt_init` / `qt_convert` / `qt_shutdown`),
  superseded by the per-runtime API (`qt_runtime_create` / `_convert` /
  `_destroy`) shipped in v0.2.0-dev.7. No Dart API change.
- `QtShimBindings.qtInit`, `qtConvertGlobal`, `qtShutdown` fields; C
  library exports reduced from 7 to 4 symbols. Dart callers unaffected.

### Tests

- 41/41 passing (was 29 in v0.2.1). Added coverage for
  `RendererOptions` serialization, `BundleSource` round-trip, and
  typed-vs-`Arg` output equivalence.

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
