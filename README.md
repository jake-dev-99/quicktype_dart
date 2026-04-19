# quicktype_dart

**Cross-platform type generation from JSON, JSON Schema, GraphQL, or TypeScript.**
Produces Dart, Kotlin, Swift, TypeScript — and 18 other languages — either at
build time via `build_runner` or at runtime from in-memory data.

Think of it as a **[pigeon](https://pub.dev/packages/pigeon)-analogue with
arbitrarily-nested typed data**. Where pigeon gives you one-layer-deep method
channel contracts, `quicktype_dart` gives you typed data classes with full
nesting — on every platform, from a single JSON source of truth.

A thin Dart wrapper around the [quicktype](https://quicktype.io) code
generator, embedded in a [QuickJS](https://bellard.org/quickjs/) runtime on
native targets and `dart:js_interop` on web.

---

## Install

```yaml
dependencies:
  quicktype_dart: ^0.9.0
```

No other tooling required for Flutter apps on macOS, iOS, Linux, Windows,
Android, or Web — `quicktype_dart` embeds quicktype-core in a QuickJS
runtime (native platforms) or calls through `dart:js_interop` to the
browser's JS engine (web), and ships the JS bundle as a Flutter asset.
~ms per generation after a ~1s first-call warm-up.

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

Pass language-specific flags via the typed `options:` parameter:

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

Every target has a matching `*RendererOptions` class —
`DartRendererOptions`, `KotlinRendererOptions`, `SwiftRendererOptions`,
`TypeScriptRendererOptions`, `CSharpRendererOptions`,
`PythonRendererOptions`, etc. IDE autocomplete gives you every flag the
underlying renderer accepts.

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
`quicktype_dart:swift`, `quicktype_dart:typescript`. Enable any
combination — each produces the matching output extension next to the
source.

See [`example/`](example/) for a minimal working setup.

---

## Config-driven batch generation

For non-builder flows (CLIs, CI pipelines), configure sources and
targets in `quicktype.json` and drive them through the `Quicktype`
orchestrator:

```dart
import 'package:quicktype_dart/quicktype_dart.dart';

final qt = Quicktype(Config.loadOrDefaults('quicktype.json'));
final commands = await qt.buildCommandsFromConfig();
final results = await qt.executeAll(commands);
```

`Config` exposes four constructors for different loading flavors:

- `Config.fromFile(path)` — throws `ConfigException` on missing/malformed.
- `Config.loadOrDefaults(path)` — falls back to built-in defaults.
- `Config.fromMap(map)` — for tests and in-memory configs.
- `Config.defaults()` — the built-in defaults directly.

Multiple `Quicktype` / `Config` instances can coexist in a single
process — there are no singletons.

---

## Transports

`QuicktypeDart.generate` and `generateFromString` accept a `transport:`
parameter. **Prefer `auto`** — the others are escape hatches for tests,
benchmarks, or environments where the default picks wrong.

```dart
// default — FFI if available, else Process
await QuicktypeDart.generate(..., transport: GenerateTransport.auto);

// force in-process QuickJS
await QuicktypeDart.generate(..., transport: GenerateTransport.ffi);

// always shell out to `quicktype`
await QuicktypeDart.generate(..., transport: GenerateTransport.process);
```

Tune the subprocess timeout via a static:

```dart
QuicktypeDart.processTimeout = const Duration(minutes: 10);
```

Under `ffi`, the first call warms up the embedded runtime (~1s to parse
the bundled quicktype-core). Subsequent calls in the same process run in
~ms. Each Dart isolate gets its own runtime — QuickJS is single-threaded.

---

## Supported target languages

C • C++ • C# • Dart • Elixir • Elm • Flow • Go • Haskell • Java •
JavaScript • Kotlin • Objective-C • PHP • JS PropTypes • Python • Ruby •
Rust • Scala 3 • Smithy • Swift • TypeScript

Each [`TargetType`](https://pub.dev/documentation/quicktype_dart/latest/quicktype_dart/TargetType.html)
value has a matching `*RendererOptions` class exposing the
language-specific flags as named constructor parameters. Null fields are
omitted, so unset options inherit quicktype-core's defaults.

---

## Two ways to think about this package

1. **"JSON → typed models, everywhere"** — you have JSON samples (API
   responses, fixtures, schemas) and want typed data classes in whatever
   language your app's using. Point the builder at the folder, walk
   away.
2. **"One source of truth across platforms"** — you're writing a
   Flutter/iOS/Android/web app with shared data contracts. Define the
   shape once (as a JSON sample or JSON Schema), generate Dart for your
   Flutter code, Kotlin for Android native, Swift for iOS native,
   TypeScript for the web client. Unlike pigeon, nesting works the
   whole way down.

---

## Bundle source

The ~2.9MB quicktype-core JS bundle ships with the plugin by default —
embedded in the C library on native and shipped as a Flutter asset on
web. Apps that prefer to load from a CDN (or their own origin) can
switch:

```dart
QuicktypeDart.setBundleSource(BundleSource.remote(
  Uri.parse('https://cdn.example.com/quicktype_bundle.js'),
  integrity: 'sha384-…', // optional Subresource Integrity hash
));

// Subsequent calls use the remote bundle.
```

`BundleSource.remote` is honored on both web and native. On native the
bytes are fetched via `HttpClient` with a 60-second body-read timeout,
cached under the system temp dir keyed by a URL hash, written
atomically, and verified against `integrity` before being fed to
QuickJS. SRI tokens support `sha256-…`, `sha384-…`, and `sha512-…`;
malformed base64 is rejected at parse time.

### Shedding the embedded bundle (~2.9MB per binary)

If every call site uses `BundleSource.remote`, the embedded copy is
dead weight. On CMake-driven targets (Linux / Windows / Android),
rebuild the native library with:

```bash
cmake -S native -B build -DQT_EMBED_BUNDLE=OFF
cmake --build build
```

On macOS / iOS (CocoaPods), define `QT_NO_EMBEDDED_BUNDLE` in the pod's
`OTHER_CFLAGS` and remove `Classes/bundle_data.c` from the source set.

Once embedding is off,
`QuicktypeDart.setBundleSource(BundleSource.remote(...))` **must** be
called before the first generate — the library will otherwise return an
error that the embedded bundle is unavailable.

---

## Roadmap

- **v0.9.0** — current. Final docs + polish before the RC cut.
- **v1.0.0-rc.1** — next. Tag + pub.dev publish once 0.9.x has baked.

See [CHANGELOG.md](CHANGELOG.md) for the per-version detail.

---

## License

BSD-3-Clause. See [LICENSE](LICENSE).
