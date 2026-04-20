# Smoke tests

Scripts under `tool/smoke/` exercise code paths that are awkward to
reach from `test/` — FFI binaries with non-default build flags,
isolate-level concurrency on the native runtime, remote bundle
fetching via `file://`, and so on.

## Status

| Script                    | Invoked by CI?            | Purpose                                                                                   |
|---------------------------|---------------------------|-------------------------------------------------------------------------------------------|
| `smoke.dart`              | No (manual dev-loop)      | End-to-end generate via the auto transport; sanity check after touching the facade.       |
| `ffi_smoke.dart`          | No (manual dev-loop)      | Pins `GenerateTransport.ffi` + the embedded bundle; regression check for FFI startup.    |
| `ffi_isolate_smoke.dart`  | No (manual dev-loop)      | Spins multiple isolates against `QtFfiRuntime.create`, verifying per-isolate runtimes.    |
| `ffi_remote_smoke.dart`   | No (manual dev-loop)      | Pairs embedded FFI with `BundleSource.remote(...)` over a local HTTP fixture.             |
| `ffi_noembed_smoke.dart`  | **Yes** (`ffi-noembed` CI job) | Builds native/ with `-DQT_EMBED_BUNDLE=OFF` and proves the runtime works via remote bundle. |

Only `ffi_noembed_smoke.dart` is wired into CI today, via the
`ffi-noembed` job in `.github/workflows/ci.yml`. The other four are
manual-only — run them locally after material changes to the FFI
runtime, the bundle loader, or the facade dispatch logic.

## Running locally

```bash
# The manual-loop scripts expect build/native/libquicktype_dart.dylib
# (or .so / .dll) to exist. Build it first:
cmake -S native -B build/native && cmake --build build/native

dart run tool/smoke/smoke.dart
dart run tool/smoke/ffi_smoke.dart
dart run tool/smoke/ffi_isolate_smoke.dart
dart run tool/smoke/ffi_remote_smoke.dart
```

For `ffi_noembed_smoke.dart` specifically, use the `OFF` flag and run
either from a dedicated build dir or overlay the main one:

```bash
cmake -S native -B build/native -DQT_EMBED_BUNDLE=OFF
cmake --build build/native
dart run tool/smoke/ffi_noembed_smoke.dart
```

Exit code 0 = pass. All scripts write human-readable `OK —` / `FAIL:`
lines to stdout/stderr; no test harness wrapping.
