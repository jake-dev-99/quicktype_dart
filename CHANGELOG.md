# Changelog

## 0.6.0

**Breaking-change release — dead code removal + strict mode.**
Cleans up the API surface for the road to 1.0, tightens the contract
around malformed configs, and removes an unused dependency.

### Removed — breaking

- **`SchemaValidator`** — exported but never used in any code path
  since the 0.4.0 deprecation. Deleted. Re-introduce with a real
  consumer if needed.
- **`json_schema: ^5.2.1`** runtime dependency — only used by
  `SchemaValidator`. Dropping it shrinks the transitive dep closure.

### Changed — breaking

- **Renderer-option coercion is now strict.** `TypeConfig.fromJson`
  previously accepted any value and silently stringified unknown types
  with a warning. Now non-`bool`/`String`/`null` values raise a
  [ConfigException]. A typo like `use-freezed: 1` or
  `part-name: [foo]` fails loud at config-load time instead of
  producing mystery output at generate time.
- **Label sanitization now appends a 6-char content hash** when any
  character was substituted. `'User:Data'` and `'User-Data'` previously
  both mapped to `'User_Data'` and silently overwrote each other's
  temp files; they now become `'User_Data_<hash1>'` and
  `'User_Data_<hash2>'` so they coexist. Alphanumeric labels pass
  through unchanged.

### Changed

- `Quicktype.executeAll` no longer emits the `========================`
  visual separator — presentation belongs to the CLI layer, not the
  library.
- `Quicktype.execute` uses `Log.info` for progress messages instead of
  `Log.off`. `Log.off` remains for CLI-only always-visible output.
- `_defaultTargets` flattened into a per-target helper
  (`_detectFilesForTarget`) for readability.
- Magic number `substring(0, 16)` in the native-bundle cache path is
  now a named `_cacheKeyLength` constant with a comment explaining
  the 64-bit entropy choice.
- `QtShimBindings._lib` now has a docstring explaining why the field
  exists (keeps the DynamicLibrary alive while function pointers are
  in use).

## 0.5.0

**Breaking-change release — de-singleton architecture.** Removes the
`Config` and `Quicktype` process-wide singletons, enables multi-config
use in a single process, and renames the internal facade file to match
its public role.

### Removed — breaking

- `Config.initialize(...)` / `Config.reset()` — the singleton factory
  is gone. Build a `Config` directly with `Config.fromFile(path)`,
  `Config.fromMap(map)`, `Config.defaults()`, or
  `Config.loadOrDefaults(path)` (the last is the one the CLI uses —
  "load if present, otherwise defaults").
- `Quicktype.initialize(...)` / `Quicktype.reset()` — replaced with a
  plain constructor: `Quicktype(Config config)`. Multiple instances
  with different configs coexist without sharing state.

### Changed — breaking

- `Config` is now `@immutable`; its `sources` and `targets` maps are
  still the same shape and type.
- `Quicktype.config` is `final` (was `late`).

### Changed

- `lib/src/quicktype_dart.dart` renamed to `lib/src/facade.dart`.
  Purely internal — the public `package:quicktype_dart/quicktype_dart.dart`
  export surface is unchanged.
- `GenerateTransport` doc now leads with "Prefer `auto`", clarifying
  that `ffi` / `process` are escape hatches for tests and pinned
  environments rather than everyday choices.
- `QuicktypeCommand`, `QuicktypeResult`, `QuicktypeException`,
  `TypeConfig`, and `ConfigException` now carry `@immutable` from
  `package:meta` — the contract was already honored, the annotation
  just makes it enforceable.

### Added dependency

- `meta: ^1.16.0` (runtime) — needed for `@immutable`. Pulled in
  transitively by pretty much every Dart package already; listing it
  explicitly avoids relying on a transitive.

### Migration

```dart
// before (0.4.x)
final qt = Quicktype.initialize('quicktype.json');
await qt.executeAll(await qt.buildCommandsFromConfig());
Quicktype.reset();

// after (0.5.0)
final qt = Quicktype(Config.loadOrDefaults('quicktype.json'));
await qt.executeAll(await qt.buildCommandsFromConfig());
// No reset() — let the instance go out of scope.
```

Direct `Config` users:

```dart
// before
final cfg = Config.initialize('quicktype.json');

// after — pick the one that matches your intent:
final cfg = Config.fromFile('quicktype.json');       // throws if missing
final cfg = Config.loadOrDefaults('quicktype.json'); // falls back if missing
final cfg = Config.fromMap(parsedJsonMap);           // from an in-memory map
final cfg = Config.defaults();                       // built-in defaults
```

## 0.4.6

**Resource safety + error propagation polish — Batch C of the road to
1.0.0-rc.1.** No public API additions or removals. Seven quality-of-
implementation improvements to make subprocess, web-bundle, and cache
error paths both safer and clearer.

### Fixed

- **Process transport logs subprocess stdout/stderr on success**
  (`lib/src/backend_io.dart`). Deprecation notices and compatibility
  warnings emitted by `quicktype` no longer vanish into the void —
  stdout lands on `Log.info`, stderr on `Log.warning`.
- **Subprocess `command` field in thrown exceptions is now
  shell-quoted** via a new `lib/src/utils/shell.dart`. Args with
  whitespace, quotes, or shell metacharacters get single-quoted so
  the failing command is copy-pastable. (Pure formatting — we still
  pass argv directly to `Process.run`, never through a shell.)
- **Temp-dir cleanup survives a Windows file lock**
  (`lib/src/backend_io.dart`). On a first-pass delete failure the path
  is queued for a second-chance sweep at the start of the next
  `_runViaProcess` call, instead of leaking into the user's temp dir.
- **Web bundle loader replaces the 25 ms busy-wait with an
  event-driven + exponential-backoff hybrid**
  (`lib/src/backend_web.dart`). When a `<script data-quicktype-dart>`
  tag was injected by someone else, we now listen for its load/error
  events and only poll (2 → 4 → 8 → … ms, capped at 100 ms) as a
  fallback for the already-fired case. Overall budget raised from 5 s
  to 15 s to cover cold-cache fetches.
- **Web bundle timeout vs. corrupt-bundle errors are now distinct
  messages**. A timeout reports "timed out … waiting for
  globalThis.qtConvert"; a completed-but-empty symbol reports "the
  bundle … is either corrupt or not a quicktype_dart bundle". Callers
  can tell the two failure modes apart at a glance.
- **SRI parse rejects malformed base64 and empty hashes at parse time**
  (`lib/src/ffi/native_bundle_cache.dart`). Previously a token like
  `'sha256-!!!not-base64!!!'` sailed through `_parseSri` only to blow
  up with a bare `FormatException` deep in the hash routine; now it
  cleanly fails the integrity check like any other bad token.
- **FFI `size_t` ↔ `int` bound documented**
  (`lib/src/ffi/qt_shim_bindings.dart`). Clarifies that the bundle
  length cap is well beyond any realistic quicktype-core bundle on
  every platform Dart supports.

### Added

- `lib/src/utils/shell.dart` — `shellQuote` and `formatCommand`
  helpers. Internal, unit-tested, reusable by future tooling.

## 0.4.5

**Lint + packaging hygiene — Batch B of the road to 1.0.0-rc.1.** No
runtime behavior change; the surface of the package stays identical.
This release turns on the full `package:lints/recommended.yaml` set
plus strict-casts / strict-inference / strict-raw-types and fixes every
resulting warning, wires CI, automates version stamping, and cleans up
the pub tarball contents.

### Added

- **Strict analyzer + lint suite** — `analysis_options.yaml` now
  inherits `package:lints/recommended.yaml` and adds 18 hardening
  rules. `strict-casts`, `strict-inference`, and `strict-raw-types`
  are all on. CI runs with `--fatal-infos --fatal-warnings`.
- **`tool/sync_version.dart`** — one command keeps `pubspec.yaml`,
  `lib/src/version.dart`, `android/build.gradle`, and the iOS/macOS
  podspecs in lockstep. Runs in check-mode in CI (fails the job on
  drift) and accepts `--write` locally to apply. Closes the regression
  path that left 0.4.1–0.4.3 tags with a stale `pubspec`.
- **`.github/workflows/ci.yml`** — per-PR matrix (Ubuntu / macOS /
  Windows) runs `dart format`, `dart analyze`, `dart test`,
  `tool/sync_version.dart`, and `dart pub publish --dry-run`.
  Required status checks come in Batch G.5.

### Changed

- **`entrypoint_cli.dart`** — `options['help']` / `options['version']`
  replaced with `ArgResults.flag(...)` and `options['config']` with
  `ArgResults.option(...)`, eliminating the `dynamic` returns the new
  strict-casts mode surfaced.
- **`_generateFromConfig`** parameter is now typed `String configPath`.
- **`Config._parseTypeConfigs`** validates per-entry list items as
  `Map<String, dynamic>` before handing them to `TypeConfig.fromJson`,
  replacing the implicit `dynamic` cast in the old `.map(...).toSet()`
  pipeline with an explicit loop that raises a clear `ConfigException`
  on the first malformed entry.
- **`backend_io.dart`** temp-dir + output-file checks switched to
  sync `existsSync`/`deleteSync` variants (flagged by
  `avoid_slow_async_io`).
- **`lib/src/utils/file_resolver.dart`** `as Path` prefix renamed to
  the conventional lowercase `as p` (fixes `library_prefixes`).
- **Doc comments in `lib/src/models/enums.dart`** wrap `List<T>` and
  `<header.h>` in backticks so dartdoc stops interpreting them as
  HTML.
- **`.pubignore`** — collapsed the per-file smoke-test exclusion list
  to a `bin/*_smoke.dart` glob, catching the two existing smoke files
  (`ffi_noembed_smoke.dart`, `ffi_remote_smoke.dart`) that weren't
  listed and removing two references to files that never existed.

### Dev dependencies

- `lints: ^5.0.0` added to `dev_dependencies:`. Not a runtime
  dependency — package consumers don't pay for it.

## 0.4.4

**Correctness hotfix release — Batch A of the road to 1.0.0-rc.1.** All
fixes are latent-bug repairs; no public API is removed or renamed. The
`QuicktypeException` class gains optional `cause` and `stackTrace` fields
(additive), and `QuicktypeDart.processTimeout` is a new tunable static.

Note: this is the first release where `pubspec.yaml`, the iOS/macOS
podspecs, and `android/build.gradle` all carry a matching version — the
0.4.1/0.4.2/0.4.3 tags that existed upstream never landed pubspec bumps
on `main`, so this release collapses back to `pubspec` as source of
truth. A `tool/sync_version.dart` script in Batch B will prevent future
drift.

### Fixed

- **Process subprocess now has a 5-minute default timeout**
  (`lib/src/backend_io.dart`). A hung `quicktype` child can no longer
  block build_runner indefinitely. Configurable via
  `QuicktypeDart.processTimeout`.
- **Remote bundle fetch has a 60-second total-body timeout**
  (`lib/src/ffi/native_bundle_cache.dart`). Previously only the TCP
  connect was bounded, so a slow-trickling CDN could hang the isolate
  forever.
- **Atomic cache writes** (`lib/src/ffi/native_bundle_cache.dart`).
  Concurrent isolates racing a bundle fetch can no longer observe a
  half-written file — writes go through `tmp + rename`.
- **Corrupted cache files are now deleted** on integrity-check failure
  so a bad write doesn't poison subsequent reads
  (`lib/src/ffi/native_bundle_cache.dart`).
- **`QtFfiRuntime.instance()` is now serialized through a `Completer`**
  (`lib/src/ffi/ffi_runtime.dart`), so two concurrent callers share one
  allocation instead of each initializing a native runtime and leaking
  the loser.
- **FFI generate-path allocations migrated to `package:ffi` `Arena`**
  (`lib/src/ffi/ffi_runtime.dart`). If `jsonEncode` throws mid-
  allocation, every already-allocated pointer is freed.
- **`Config` loader validates shapes before casting**
  (`lib/src/config.dart`). Previously `as Map<String,dynamic>`,
  `as List`, and a force-unwrapped `matchingType!` crashed on any
  malformed `quicktype.json`; now each failure raises a
  `ConfigException` with a field path and the expected shape.
- **Subprocess failures no longer swallow the underlying error**
  (`lib/src/quicktype.dart`, `lib/src/backend_io.dart`).
  `QuicktypeException` now carries the original `cause` and
  `stackTrace`, and its `toString()` surfaces the wrapped cause.
- **CLI version string reads from `pubspec.yaml`** via a new generated
  constant at `lib/src/version.dart`. `dart run quicktype_dart
  --version` no longer prints a stale `v1.0.0`.

### Added

- `QuicktypeException.cause` and `QuicktypeException.stackTrace`
  (optional, additive).
- `QuicktypeDart.processTimeout` — tunable wall-clock cap for the
  subprocess transport.
- `lib/src/version.dart` exposing `packageVersion` so downstream tooling
  can read the current version without parsing `pubspec.yaml`.

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

Native remote-bundle support + opt-out embedding. Finishes the remote-bundle
story started in v0.3.0, where only Flutter Web honored
`BundleSource.remote`. Apps that lean on remote bundles now have a path to
~2.9MB native-binary savings.

### Remote bundle on native (macOS / iOS / Linux / Windows / Android)

- `QtFfiRuntime.create({BundleSource? bundleSource})` now dispatches on
  the configured source. `BundleSource.remote(Uri, {integrity})` fetches
  the JS via `dart:io` `HttpClient`, caches it under the system temp dir
  keyed by a URL hash, and verifies an optional Subresource-Integrity
  token (`sha256-…`, `sha384-…`, or `sha512-…`) before loading it into
  QuickJS. `file://` URLs are supported for tests and tooling.
- `QuicktypeDart.setBundleSource(...)` now affects native as well as web.
  The default remains `BundleSource.embedded()` — zero behavior change
  for callers that don't touch it.

### Opt-out embedding — shed ~2.9MB per-platform

- New CMake option `QT_EMBED_BUNDLE` (default `ON`). Build with
  `-DQT_EMBED_BUNDLE=OFF` to skip the embedded prelude+bundle; the
  library then requires a runtime `BundleSource.remote(...)` before the
  first generate call. Covers Linux / Windows / Android (all CMake-driven).
- libquicktype_dart.dylib: **~4.0MB → ~1.1MB** with `QT_EMBED_BUNDLE=OFF`
  on a local macOS build.
- macOS / iOS use the CocoaPods podspec rather than CMake. To strip the
  bundle there, define `QT_NO_EMBEDDED_BUNDLE` in the pod's
  `OTHER_CFLAGS` and remove `Classes/bundle_data.c` from the source set.

### Native C API refactor

- `qt_runtime_create` now loads only the prelude — embedded-bundle
  loading moved to a new `qt_runtime_load_embedded(QtRuntime*)` (returns
  `-2` when the library was built with `QT_NO_EMBEDDED_BUNDLE`), and a
  new `qt_runtime_load_bundle(QtRuntime*, const char*, size_t)` accepts
  caller-provided JS. No Dart API change — `QtFfiRuntime.create()` still
  returns a fully-initialized runtime.

### Dependencies

- Adds `crypto: ^3.0.0` for on-disk SRI integrity verification.

### Tests

- `test/native_bundle_cache_test.dart` covers sha256/384/512 integrity,
  mismatch rejection, malformed tokens, and unsupported algorithms.
- `bin/ffi_remote_smoke.dart` + `bin/ffi_noembed_smoke.dart` exercise
  the remote path end-to-end — the latter against a library built with
  `QT_EMBED_BUNDLE=OFF`.
- 48/48 test suite passing; all three legacy FFI smokes
  (`ffi_smoke`, `ffi_args_smoke`, `ffi_isolate_smoke`) still green.

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
