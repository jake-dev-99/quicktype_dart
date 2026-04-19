# quicktype_dart example

Two ways to use `quicktype_dart` — both demonstrated here.

## 1. Runtime generation

See [example.dart](example.dart). Run with:

```bash
dart run example.dart
```

Converts an in-memory JSON payload into a Dart class via
`QuicktypeDart.generate`, prints the generated source.

## 2. Build-time generation

[lib/models/user.qt.json](lib/models/user.qt.json) is a sample input.
[build.yaml](build.yaml) wires up the `quicktype_dart:dart` builder.

```bash
dart run build_runner build --delete-conflicting-outputs
```

…produces `lib/models/user.dart` alongside the JSON sample.

Both flows shell out to the `quicktype` Node CLI. Install it with
`npm install -g quicktype` before running.
