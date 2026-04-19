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
  quicktype_dart: ^0.1.0
```

And install the `quicktype` CLI globally:

```bash
npm install -g quicktype
```

> **v0.1.0 requires the node CLI.** `quicktype_dart` shells out to
> `quicktype` for codegen. v0.2.0 will embed quicktype-core via a QuickJS
> FFI plugin so the Node dependency goes away on mobile.

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

Pass language-specific flags via the typed arg registry — e.g. Dart with
`--use-freezed --null-safety`:

```dart
await QuicktypeDart.generate(
  label: 'User',
  data: {'id': 1, 'name': 'Jake'},
  target: TargetType.dart,
  args: [
    DartArgs.useFreezed..value = true,
    DartArgs.nullSafety..value = true,
  ],
);
```

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

## Roadmap

- **v0.1.x** — current. Build-time + runtime via the Node CLI.
- **v0.2.0** — Flutter FFI plugin embedding quicktype-core via QuickJS.
  Removes the Node dependency on mobile. Spike showed ~2ms per convert
  after warmup, 680KB of native code, 2.8MB of bundled JS.

---

## License

BSD-3-Clause. See [LICENSE](LICENSE).
