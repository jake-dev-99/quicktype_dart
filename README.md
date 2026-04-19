# quicktype_dart

**Cross-platform type generation from JSON, JSON Schema, GraphQL, or TypeScript.**
Produces Dart, Kotlin, Swift, TypeScript — and 18 other languages — either at
build time via `build_runner` or at runtime from in-memory data.

Think of it as a **[pigeon](https://pub.dev/packages/pigeon)-analogue with
arbitrarily-nested typed data**. Where pigeon gives you one-layer-deep method
channel contracts, `quicktype_dart` gives you typed data classes with
full nesting — on every platform, from a single JSON source of truth.

A thin Dart wrapper around the [quicktype](https://quicktype.io) code generator.

---

## Install

```yaml
dependencies:
  quicktype_dart: ^0.3.0
```

No other tooling required for Flutter apps on macOS, iOS, Linux, Windows,
Android, or Web — `quicktype_dart` embeds quicktype-core in a QuickJS
runtime (native platforms) or calls through `dart:js_interop` to the
browser's JS engine (web), and ships the JS bundle as a Flutter asset.
~2ms per generation after a ~1s first-call warm-up.

For dev-time tooling (CI codegen, build_runner flows) on machines that
lack the FFI plugin, install the `quicktype` CLI:

```bash
npm install -g quicktype
```

`QuicktypeDart.generate` will automatically prefer the embedded FFI
runtime and fall back to the CLI when the native library isn't available.

---

## Runtime usage — `QuicktypeDart.generate`

Convert JSON-encodable Dart data to generated source code on demand:

```dart
import 'package:quicktype_dart/quicktype_dart.dart';

final dartSource = await QuicktypeDart.generate(
  label: 'User',
  data: [
    {'id': 1, 'name': 'Jake', 'roles': ['admin']},
  ],
  target: TargetType.dart,
);
print(dartSource); // → `class User { ... }` with fromJson/toJson
```

Pass language-specific flags via the typed `options:` parameter — e.g.
Dart with `--use-freezed --null-safety`:

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

Every target has a matching `*RendererOptions` class:
`DartRendererOptions`, `KotlinRendererOptions`, `SwiftRendererOptions`,
`TypeScriptRendererOptions`, `CSharpRendererOptions`, `PythonRendererOptions`,
etc. IDE autocomplete gives you every flag the underlying renderer accepts.

(The older `args: [DartArgs.useFreezed..value = true]` pattern still works
but is `@Deprecated` — removal planned for v0.4.0.)

Already have the JSON as a string? Skip the re-encode:

```dart
await QuicktypeDart.generateFromString(
  label: 'User',
  json: await File('sample.json').readAsString(),
  target: TargetType.kotlin,
);
```

---

## Build-time usage — `build_runner` integration

Drop a `*.qt.json` sample next to your model files, opt into the builder
in your app's `build.yaml`, and run the build.

**1.** Add the builder to your app's `build.yaml`:

```yaml
targets:
  $default:
    builders:
      quicktype_dart:dart:
        enabled: true
        options:
          target: dart
          args:
            use-freezed: true
            null-safety: true
```

**2.** Drop a sample at `lib/models/user.qt.json`:

```json
{
  "id": 42,
  "name": "Jake",
  "roles": ["admin", "editor"]
}
```

**3.** Run the build:

```bash
dart run build_runner build
```

You'll get `lib/models/user.dart` generated alongside the sample.

Builders available: `quicktype_dart:dart`, `quicktype_dart:kotlin`,
`quicktype_dart:swift`, `quicktype_dart:typescript`. Enable any combination —
each produces the matching output extension next to the source.

---

## Transports

`QuicktypeDart.generate` and `generateFromString` accept a `transport:`
parameter:

```dart
await QuicktypeDart.generate(
  // ...
  transport: GenerateTransport.auto,   // default — FFI if available, else Process
);
await QuicktypeDart.generate(
  // ...
  transport: GenerateTransport.ffi,    // force in-process QuickJS
);
await QuicktypeDart.generate(
  // ...
  transport: GenerateTransport.process, // always shell out to `quicktype`
);
```

Under `ffi`, the first call warms up the embedded runtime (~1s to parse
the bundled quicktype-core). Subsequent calls in the same process run in
~ms. Each Dart isolate that calls `QuicktypeDart.generate` gets its own
runtime — QuickJS is single-threaded, and `QtFfiRuntime` enforces that
isolation.

For long-running workflows or test setups, manage the runtime lifecycle
explicitly:

```dart
import 'package:quicktype_dart/src/ffi/ffi_runtime.dart';

final runtime = await QtFfiRuntime.create();
try {
  await runtime.generate(/* ... */);
} finally {
  runtime.dispose();
}
```

---

## Supported target languages

C • C++ • C# • Dart • Elixir • Elm • Flow • Go • Haskell • Java • JavaScript
• Kotlin • Objective-C • PHP • JS PropTypes • Python • Ruby • Rust • Scala 3
• Smithy • Swift • TypeScript

Each [`TargetType`](https://pub.dev/documentation/quicktype_dart/latest/quicktype_dart/TargetType.html)
value has a corresponding `*Args` class exposing the language-specific CLI
flags as typed getters — `DartArgs.useFreezed`, `SwiftArgs.structOrClass`,
`KotlinArgs.framework`, etc.

---

## Two ways to think about this package

1. **"JSON → typed models, everywhere"** — you have JSON samples (API
   responses, fixtures, schemas) and want typed data classes in whatever
   language your app's using. Point the builder at the folder, walk away.
2. **"One source of truth across platforms"** — you're writing a
   Flutter/iOS/Android/web app with shared data contracts. Define the
   shape once (as a JSON sample or JSON Schema), generate Dart for your
   Flutter code, Kotlin for Android native, Swift for iOS native,
   TypeScript for the web client. Unlike pigeon, nesting works the whole
   way down.

---

## Bundle source (Flutter Web)

On Flutter Web the 2.9MB quicktype-core JS bundle ships as a plugin
asset by default. Apps that prefer a CDN can switch:

```dart
QuicktypeDart.setBundleSource(BundleSource.remote(
  Uri.parse('https://cdn.example.com/quicktype_bundle.js'),
  integrity: 'sha384-…', // optional Subresource Integrity hash
));

// Subsequent calls use the remote bundle.
```

Native targets always use the embedded QuickJS bundle in v0.3.0 —
remote bundle on native ships in v0.3.1.

---

## Roadmap

- **v0.3.0** — current. Typed `*RendererOptions` classes, Flutter Web
  remote bundle option, legacy process-global FFI API removed.
- **v0.3.1** — native remote bundle + binary-size reduction on native
  when remote is configured (strip the embedded 2.9MB JS).
- **v0.4.0** — remove the deprecated `*Args` classes in favor of
  `*RendererOptions`.

---

## License

BSD-3-Clause. See [LICENSE](LICENSE).
