# quicktype_dart native/

The `native/` tree is the C side of the plugin: a small FFI shim that wraps
[QuickJS-NG](https://github.com/quickjs-ng/quickjs) and embeds the
[quicktype-core](https://github.com/glideapps/quicktype) JS bundle, compiled
into a single shared library (`libquicktype_dart.so`,
`libquicktype_dart.dylib`, or `quicktype_dart.dll` depending on the
platform).

## Layout

```
native/
├── CMakeLists.txt        # primary build description
├── quickjs/              # vendored QuickJS-NG sources (MIT)
├── shim/
│   ├── qt_shim.h         # public FFI surface
│   ├── qt_shim.c         # the shim implementation
│   ├── qt_shim.exports   # symbol list for -exported_symbols_list on Apple
│   └── embed_bundle.py   # turns prelude.js + bundle.js into bundle_data.c
└── bundle/               # source JS (prelude + bundled quicktype-core)
    ├── prelude.js        # environment shims QuickJS needs to host the bundle
    ├── quicktype_bundle.js # minified quicktype-core produced by build_bundle.sh
    ├── build_bundle.sh   # dev-only rebundle workflow
    ├── package.json      # dev-only dependency list for build_bundle.sh
    └── shim.mjs          # esbuild entry point used by build_bundle.sh
```

## Build options

The only tunable exposed through CMake is `QT_EMBED_BUNDLE` (default `ON`).
With it on, `embed_bundle.py` runs at configure time and produces
`bundle_data.c`, which the shared library compiles in — a ~2.9MB increase
to the final binary, but the library works with no runtime dependencies.

Turn it off to ship a lean (~1.1MB on macOS arm64) binary that fetches the
JS at runtime:

```bash
cmake -S native -B build -DQT_EMBED_BUNDLE=OFF
cmake --build build
```

When the flag is off, the shared library requires the Dart side to pair
with `BundleSource.remote(...)` — see the top-level README's
"Bundle source" section for how that's wired up.

## Platform wrappers

Flutter's build systems look at each platform's subdirectory for the
plugin's native integration. All three of them delegate here:

- **macOS / iOS** use CocoaPods. `macos/quicktype_dart.podspec` and
  `ios/quicktype_dart.podspec` reference forwarder files in their
  respective `Classes/` directories. CocoaPods forbids `source_files`
  pointing outside the podspec dir, so each forwarder is a one-line
  `#include "../../native/shim/qt_shim.c"` (and similar for the quickjs
  sources). This is the cleanest way to keep a single source of truth
  while satisfying the podspec constraint.
- **Linux** / **Windows** use thin `linux/CMakeLists.txt` /
  `windows/CMakeLists.txt` wrappers that `add_subdirectory(../native)`
  and reference the `quicktype_dart` target produced here.
- **Android** builds via Gradle's `externalNativeBuild` block pointing at
  `android/CMakeLists.txt`, which likewise delegates.

## Regenerating the bundle

The shipped `bundle/quicktype_bundle.js` is pre-built. Developers who want
to track an upstream quicktype-core release can rebuild it:

```bash
cd native/bundle
npm install
./build_bundle.sh
```

`build_bundle.sh` uses `esbuild` to bundle quicktype-core into a single
IIFE that declares `globalThis.qtConvert`. The output lands in place at
`native/bundle/quicktype_bundle.js`; a subsequent `cmake --build` picks
it up through `embed_bundle.py`.

## License

This directory ships under MIT, matching the rest of the package.
`quickjs/` is vendored QuickJS-NG (MIT) with its original `LICENSE` file
preserved in place.
