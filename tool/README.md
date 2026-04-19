# `tool/` — dev-only scripts

Everything here is excluded from the pub.dev tarball via `.pubignore`.
Consumers never see it; contributors use it to regenerate bundles,
sync versions, and run smoke tests.

## Contents

### `sync_version.dart`
Keeps the version stamp in `pubspec.yaml`, `lib/src/version.dart`,
`android/build.gradle`, and the iOS/macOS podspecs in lockstep.

```bash
dart run tool/sync_version.dart           # check — fails if out of sync
dart run tool/sync_version.dart --write   # rewrite drifted files
```

Runs in CI; every PR has to pass it before merge.

### `refresh_bundle.dart`
Regenerates the embedded quicktype-core JS bundle that ships inside
the native library. Use when bumping quicktype-core or touching the
`native/bundle/shim.mjs` entrypoint.

Prereqs:
- Node / npm installed.
- `cd native/bundle && npm install` run at least once.

```bash
dart run tool/refresh_bundle.dart
```

Output:
- `native/bundle/quicktype_bundle.js` — rebundled IIFE.
- `native/shim/bundle_data.c` — C byte arrays consumed by CMake when
  `QT_EMBED_BUNDLE=ON` (the default).

After regen, rebuild native:
```bash
cmake -S native -B build/native && cmake --build build/native
```

### `install_hooks.dart`
Installs a git `pre-commit` hook that runs `dart format --set-exit-if-changed`
and `dart analyze --fatal-infos --fatal-warnings` before every commit.
Opt-in — never runs without an explicit invocation.

```bash
dart run tool/install_hooks.dart
```

To remove: `rm .git/hooks/pre-commit`.

### `smoke/`
One-off diagnostic scripts that exercise the FFI runtime, process
transport, and remote bundle loading. Not part of the published test
suite — run manually when debugging platform-specific issues.

```bash
dart run tool/smoke/ffi_smoke.dart
dart run tool/smoke/ffi_remote_smoke.dart
dart run tool/smoke/ffi_isolate_smoke.dart
dart run tool/smoke/ffi_noembed_smoke.dart
dart run tool/smoke/smoke.dart
```

### `node_modules/` (generated)
`npm install` output for the bundled `quicktype` CLI used by the
Process-transport fallback. Run `cd tool && npm install` to create.
Never committed.
