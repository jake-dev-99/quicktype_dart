# Changelog

## 0.1.1

Hygiene-only patch. No code, API, or runtime behaviour changes.

- Rewrites `.gitignore` to cover `node_modules/`, `build/`, `.dart_tool/`,
  Flutter-generated per-platform registrants, Xcode `ephemeral/` state,
  Android NDK `.cxx/` caches, and Gradle `.gradle/` dirs.
- Removes **3929 previously-tracked build artifacts** from version control
  — mostly `tool/node_modules/` (the Node `quicktype` install was
  accidentally checked in), plus Flutter-generated files under
  `ios/Flutter/`, `macos/Flutter/`, and `linux/flutter/`. All regenerated
  by `flutter pub get` / `npm install` locally.
- Deletes `models/`, `web/src/models/`, and `pubspec.dart` — dead
  scaffold output from early quicktype runs, nothing in the package
  referenced them.

Upgrade notes: dependents pinned to `^0.1.0` pick this up automatically.
Local dev checkouts may have stale tracked copies of the now-ignored
files — `git clean -fdx` or a fresh clone resolves it.

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
