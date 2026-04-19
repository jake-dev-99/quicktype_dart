# quicktype_dart

**Typed data classes, generated from JSON, on every platform Flutter runs on.**

Give `quicktype_dart` a JSON sample and a target language (Dart, Kotlin, Swift,
TypeScript, and 18 others) and it produces an idiomatic typed model with
`fromJson`/`toJson` — at runtime from an in-memory value, or at build time via
`build_runner`.

It's a thin Dart wrapper around the [quicktype](https://quicktype.io) code
generator: the full quicktype-core engine runs in-process on every platform,
either via **FFI** (Foreign Function Interface — native code loaded directly
into your Dart VM) against an embedded **QuickJS** (a small, embeddable
JavaScript engine) on macOS/iOS/Linux/Windows/Android, or via `dart:js_interop`
against the browser's own JS engine on web. No subprocesses, no `Node`
dependency at runtime, no network calls.

```dart
import 'package:quicktype_dart/quicktype_dart.dart';

final dartSource = await QuicktypeDart.generate(
  label: 'User',
  data: {'id': 1, 'name': 'Jake', 'active': true},
  target: TargetType.dart,
);
// → "class User { int id; String name; bool active; ... }"
```

---

## Platform support

| Platform   | Transport              | Status      |
| ---------- | ---------------------- | ----------- |
| macOS      | FFI (QuickJS)          | ✅ verified |
| iOS        | FFI (QuickJS)          | ✅ verified |
| Linux      | FFI (QuickJS)          | ✅ verified |
| Windows    | FFI (QuickJS)          | ✅ verified |
| Android    | FFI (QuickJS)          | ✅ verified |
| Flutter Web| `dart:js_interop`      | ✅ verified |
| Pure Dart VM | FFI or Node CLI fallback | ✅ verified |

All platforms support runtime generation via `QuicktypeDart.generate`. The
first call warms up the embedded JS runtime (~1 second); subsequent calls
land in ~2ms.

---

## Install

```yaml
dependencies:
  quicktype_dart: ^0.4.2
```

Then `flutter pub get` (or `dart pub get` for pure-Dart projects). Nothing
else to configure for the default in-process FFI path. On platforms where
the FFI plugin isn't built (e.g. some CI images), install the optional
`quicktype` Node CLI so the Process transport can take over:

```bash
npm install -g quicktype
```

---

## Quick start — runtime generation

```dart
import 'package:quicktype_dart/quicktype_dart.dart';

Future<void> main() async {
  final source = await QuicktypeDart.generate(
    label: 'User',
    data: {
      'id': 42,
      'name': 'Jake',
      'roles': ['admin', 'editor'],
      'profile': {'age': 33, 'active': true},
    },
    target: TargetType.dart,
  );
  print(source); // class User { ... }
}
```

Already have the JSON as text? Skip the re-encode:

```dart
await QuicktypeDart.generateFromString(
  label: 'User',
  json: await File('sample.json').readAsString(),
  target: TargetType.kotlin,
);
```

### Passing language-specific options

Each target language has a typed `*RendererOptions` class exposing every
flag quicktype-core accepts:

```dart
await QuicktypeDart.generate(
  label: 'User',
  data: {'id': 1, 'name': 'Jake'},
  target: TargetType.dart,
  options: const DartRendererOptions(
    useFreezed: true,
    nullSafety: true,
    partName: 'user.g.dart',
  ),
);
```

`DartRendererOptions`, `KotlinRendererOptions`, `SwiftRendererOptions`,
`TypeScriptRendererOptions`, `CSharpRendererOptions`, `PythonRendererOptions`,
`GoRendererOptions`, etc. — one per target. Null fields are omitted, so
anything you don't set inherits quicktype-core's default.

---

## Build-time generation — `build_runner`

For models you want regenerated on every build rather than on demand:

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
{"id": 42, "name": "Jake", "roles": ["admin", "editor"]}
```

**3.** Run the build:

```bash
dart run build_runner build
```

You'll get `lib/models/user.dart` generated alongside the sample. Builders
available: `quicktype_dart:dart`, `quicktype_dart:kotlin`,
`quicktype_dart:swift`, `quicktype_dart:typescript`. Enable any combination.

---

## Example

A working runtime example lives in [`example/`](example/) with its own
[README](example/README.md). Clone the repo and `dart run example/example.dart`
to exercise three common paths: generate from a Map, switch the target
language, pass typed options.

---

## Transports

`QuicktypeDart.generate` accepts a `transport:` parameter:

```dart
transport: GenerateTransport.auto     // default — FFI if available, else Process
transport: GenerateTransport.ffi      // force in-process QuickJS
transport: GenerateTransport.process  // always shell out to `quicktype` CLI
```

Each Dart isolate that calls `generate` gets its own FFI runtime — QuickJS
is single-threaded, so `QtFfiRuntime` enforces one runtime per isolate for
you. For long-running workflows or test setups, manage the lifecycle
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

## Bundle source

The ~2.9MB quicktype-core JS bundle ships embedded in the plugin by
default. If you prefer to load it from a CDN or your own origin —
shrinking the final binary by the same 2.9MB — switch to a remote
bundle:

```dart
QuicktypeDart.setBundleSource(BundleSource.remote(
  Uri.parse('https://cdn.example.com/quicktype_bundle.js'),
  integrity: 'sha384-…', // optional Subresource Integrity hash (SRI —
                         // a tamper-detection token for third-party JS)
));
```

`BundleSource.remote` is honored on both web and native. On native, the
bytes are fetched via `HttpClient`, cached under the system temp directory
keyed by a URL hash, and verified against `integrity` before being handed
to QuickJS. SRI tokens support `sha256-…`, `sha384-…`, and `sha512-…`.

### Shedding the embedded bundle

Once every call site is on `BundleSource.remote`, you can strip the
embedded copy from the binary entirely. On CMake-driven targets (Linux,
Windows, Android):

```bash
cmake -S native -B build -DQT_EMBED_BUNDLE=OFF
cmake --build build
```

On macOS/iOS (CocoaPods): define `QT_NO_EMBEDDED_BUNDLE` in the pod's
`OTHER_CFLAGS` and drop `Classes/bundle_data.c` from the source set.

With embedding off, you **must** call
`QuicktypeDart.setBundleSource(BundleSource.remote(...))` before the first
`generate` — otherwise the library returns an error that the embedded
bundle is unavailable.

---

## Migrating from 0.3.x

v0.4.0 removed the `*Args` surface deprecated in v0.3.0. The typed
`*RendererOptions` classes are now the single public API for language
flags. The mechanical rewrite per call site:

```dart
// before
args: [DartArgs.useFreezed..value = true, DartArgs.nullSafety..value = true]

// after
options: const DartRendererOptions(useFreezed: true, nullSafety: true)
```

Nothing else about `generate` / `generateFromString` changed. The `args:`
parameter is gone; `options:` accepts any `RendererOptions` subclass.

---

## Two ways to think about this package

1. **"JSON → typed models, everywhere"** — you have JSON samples (API
   responses, fixtures, schemas) and want typed data classes in whatever
   language your app uses. Point the builder at the folder, walk away.
2. **"One source of truth across platforms"** — you're writing a
   Flutter/iOS/Android/web app with shared data contracts. Define the
   shape once (as a JSON sample or JSON Schema), then generate Dart for
   your Flutter code, Kotlin for Android native, Swift for iOS native,
   TypeScript for the web client. Unlike
   [pigeon](https://pub.dev/packages/pigeon), nesting works the whole
   way down.

---

## Supported target languages

C • C++ • C# • Dart • Elixir • Elm • Flow • Go • Haskell • Java •
JavaScript • Kotlin • Objective-C • PHP • JS PropTypes • Python • Ruby •
Rust • Scala 3 • Smithy • Swift • TypeScript

See each target's corresponding `*RendererOptions` class (e.g.
[`DartRendererOptions`](https://pub.dev/documentation/quicktype_dart/latest/quicktype_dart/DartRendererOptions-class.html),
[`SwiftRendererOptions`](https://pub.dev/documentation/quicktype_dart/latest/quicktype_dart/SwiftRendererOptions-class.html))
for the authoritative list of flags per language.

---

## FAQ

**Why is my Flutter app binary ~2.9MB larger after adding `quicktype_dart`?**
That's the embedded quicktype-core JS bundle. If every call site uses
`BundleSource.remote(...)`, switch to a no-embed native build (see
[Shedding the embedded bundle](#shedding-the-embedded-bundle)) to recover
the space.

**Do I need to bundle the `quicktype` CLI for production?**
No. The FFI path runs the full quicktype-core engine in-process via the
embedded QuickJS runtime. The `quicktype` Node CLI is only useful as a
dev-machine fallback when the FFI plugin isn't built for some reason.

**Can I use this in tests?**
Yes. Each call creates/reuses an FFI runtime scoped to the current
isolate, and the Process transport works anywhere Dart can spawn
subprocesses. The `test/generate_integration_test.dart` file covers the
common shapes.

**Does it work offline?**
Yes, with embedded bundles (the default). With
`BundleSource.remote(...)`, the first call fetches the bundle and caches
it on disk keyed by URL hash — subsequent calls are offline.

**Why QuickJS and not V8 / Hermes / JavaScriptCore?**
QuickJS is ~1MB compiled, has no external runtime dependency, and runs
the same on every platform Flutter ships to. The trade-off is slightly
slower cold-start than V8, but warm generation is still ~ms.

---

## Attribution

Built on two outstanding projects:

- **[quicktype-core](https://github.com/glideapps/quicktype)** (Apache
  License 2.0) — the JSON-to-types engine doing the actual code
  generation.
- **[QuickJS-NG](https://github.com/quickjs-ng/quickjs)** (MIT License) —
  the embeddable JS runtime vendored under `native/quickjs/`, carrying
  its original license file.

---

## Roadmap

- **v0.4.x (current)** — first release-candidate cycle. Clean typed
  `*RendererOptions` surface (v0.4.0), MIT license (v0.4.1), documentation
  polish (v0.4.2), CI + native polish (v0.4.3).
- **v0.5.0 (planned)** — post-RC work driven by community feedback.

---

## License

[MIT](LICENSE) © 2024 Jake Allen and quicktype_dart contributors.
