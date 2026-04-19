# Copilot Instructions for quicktype_dart

## Project Overview

This is a **Dart/Flutter wrapper for [quicktype](https://quicktype.io/)** - generating type-safe model code from JSON schemas, GraphQL, and TypeScript. The package wraps the Node.js quicktype CLI and provides both programmatic Dart APIs and an FFI-based native interface.

## Architecture

```
lib/
├── quicktype_dart.dart     # Public barrel — `import 'package:quicktype_dart/quicktype_dart.dart';`
├── entrypoint_cli.dart     # QuicktypeCLI — config-driven CLI
├── entrypoint_runner.dart  # QuicktypeBuilder (build_runner integration)
└── src/
    ├── config.dart                 # Config singleton — parses quicktype.json
    ├── quicktype.dart              # Quicktype singleton — orchestrates execution
    ├── quicktype_builder.dart      # QuicktypeClientBuilder — factory-style programmatic API
    ├── quicktype_dart.dart         # QuicktypeDart.convertJson — ad-hoc facade
    ├── interop.dart                # Platform interface stubs
    ├── g/bindings.g.dart           # FFI bindings (template, disabled)
    ├── utils/
    │   ├── file_resolver.dart      # Glob-based file discovery + target path resolution
    │   ├── logging.dart            # Log static facade
    │   ├── type_infer.dart         # inferLangType<T extends TypeEnum>()
    │   └── validator.dart          # SchemaValidator (JSON Schema validation)
    └── models/
        ├── type.dart               # SourceType/TargetType enums + TypeEnum + TypeConfig
        ├── command.dart            # QuicktypeCommand
        ├── result.dart             # QuicktypeResult
        ├── args.dart               # Arg base classes (SimpleArg/StringArg/BoolArg/etc.) + barrel
        └── args/
            ├── enums.dart          # Shared + language-specific enums (22 enums)
            ├── main_args.dart      # Core quicktype CLI args (--src, --lang, ...)
            └── lang_*.dart         # 22 language-specific arg classes
tool/node_modules/          # Node.js quicktype executable lives here
```

## Key Patterns

### Type Enums (`lib/src/models/type.dart`)
```dart
// Source formats
enum SourceType implements TypeEnum { json, jsonschema, graphql, typescript }

// 22 target languages with extensions and CLI arg names
enum TargetType implements TypeEnum { dart, c, cpp, csharp, elixir, elm, flow,
  go, haskell, java, javascript, kotlin, objc, php, proptypes, python, ruby,
  rust, scala, smithy, swift, typescript }
```

### Typed Arguments Pattern
Each language has its own typed argument class in `lib/src/models/args/lang_*.dart`:
```dart
// Example: lib/src/models/args/lang_dart.dart
DartArgs.nullSafety      // --null-safety
DartArgs.useFreezed      // --use-freezed
DartArgs.useJsonAnnotation
```

### Configuration (`quicktype.json`)
Config singleton loads from `quicktype.json` at project root or uses defaults. Schema:
```json
{
  "sources": { "json": [{ "path": "models/*.json" }] },
  "targets": { "dart": [{ "path": "lib/models/generated/" }] }
}
```

### Command Execution
```dart
// Ad-hoc in-memory JSON → typed code (main consumer entry point)
final dartCode = await QuicktypeDart.convertJson(
  sourceLabel: 'Person',
  sourcePayload: [{'name': 'Jake', 'age': 42}],
  targetType: TargetType.dart,
);

// Config-driven execution (singleton)
final quicktype = Quicktype.initialize();
final commands = await quicktype.buildCommandsFromConfig();
final results = await quicktype.executeAll(commands);
```

## Development Commands

```bash
# Run the CLI (via bin/quicktype_dart.dart)
dart run bin/quicktype_dart.dart

# The quicktype executable is at:
./tool/node_modules/.bin/quicktype

# Check quicktype version
./tool/node_modules/.bin/quicktype --version

# Generate code manually
./tool/node_modules/.bin/quicktype --src models/sample.json --lang dart --out lib/models/generated/sample.dart
```

## Code Conventions

1. **Singletons**: `Config`, `Quicktype` use factory constructors with `_instance` pattern. Both expose `reset()` for tests or runtime reload.
2. **Exception handling**: Custom `QuicktypeException` and `ConfigException` classes
3. **Path resolution**: Use `FileResolver` class for glob patterns and path normalization
4. **Logging**: Use `Log` class from `lib/src/utils/logging.dart` (wraps `dart:developer`)
5. **CWD safety**: the bundled `quicktype` node binary lives at `tool/node_modules/.bin/quicktype`. When calling from a non-package CWD, resolve the absolute path via `Isolate.resolvePackageUri(Uri.parse('package:quicktype_dart/'))`.

## Adding a New Target Language

1. Create `lib/src/models/args/lang_<name>.dart` with language-specific options (import `'../args.dart';`)
2. Add enum value to `TargetType` in `lib/src/models/type.dart` with argName + file extensions
3. Add the new case to `TargetType.args` switch returning `YourLangArgs.args`
4. Add a new `export 'args/lang_<name>.dart';` line in `lib/src/models/args.dart`
5. If your lang needs a new enum, add it to `lib/src/models/args/enums.dart` — don't inline into the lang file

## Important Files

- `lib/src/models/type.dart` — Central SourceType/TargetType enums + TypeEnum interface
- `lib/src/models/args/enums.dart` — Shared + language-specific enums (22 enums)
- `lib/src/config.dart` — Configuration parsing and defaults
- `lib/src/quicktype.dart` — Core execution logic (`Quicktype`, runs the node binary)
- `lib/src/models/command.dart` — `QuicktypeCommand` — a single generation task
- `lib/src/quicktype_dart.dart` — `QuicktypeDart.convertJson` facade (consumer-facing API)

## Platform Support

- Native FFI support in `quicktype_dart/` directory (C code)
- Platform-specific builds configured in `macos/`, `windows/`, `linux/`, `android/`
- Example Flutter app in `example/` directory
