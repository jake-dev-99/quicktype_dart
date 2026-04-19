# CMake entry point for the quicktype_dart native bridge.
#
# Builds:
#   qjs        — static library from the vendored quickjs-ng sources.
#   qt_shim    — shared library (libqt_shim.dylib / .so / .dll) that embeds
#                the JS bundle + prelude and links against qjs.
#
# Consumed by the Flutter FFI plugin CMake in macos/quicktype_dart.podspec
# (and the Linux / Windows variants when those phases land). Can also be
# built standalone for local testing:
#
#   cmake -S native -B build/native
#   cmake --build build/native

cmake_minimum_required(VERSION 3.15)
project(quicktype_dart LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# --- quickjs-ng as a static library --------------------------------------
# quicktype_bundle runs fine without libc bindings, so we compile just the
# four core source files rather than pulling in the full upstream build.
add_library(qjs STATIC
  quickjs/quickjs.c
  quickjs/libregexp.c
  quickjs/libunicode.c
  quickjs/dtoa.c
)
target_include_directories(qjs PUBLIC quickjs)
target_compile_options(qjs PRIVATE
  -Wno-unused-parameter
  -Wno-implicit-fallthrough
  -Wno-sign-compare
)

# --- Optional: embed the JS bundle + prelude as C arrays ------------------
# When QT_EMBED_BUNDLE is ON (default), the ~2.9MB prelude + quicktype-core
# bundle are compiled into the shared library as C byte arrays, and
# qt_runtime_load_embedded() loads them. When OFF, bundle_data.c is not
# built, QT_NO_EMBEDDED_BUNDLE is defined so qt_shim.c compiles out the
# embedded-bundle code paths, and callers are required to supply the JS
# at runtime via qt_runtime_load_bundle() (see BundleSource.remote on the
# Dart side). Turning this off sheds ~2.9MB from the final binary.
option(QT_EMBED_BUNDLE "Embed the quicktype JS bundle into the shared library" ON)

set(QT_SHIM_SOURCES shim/qt_shim.c)

if(QT_EMBED_BUNDLE)
  set(QT_BUNDLE    "${CMAKE_CURRENT_SOURCE_DIR}/bundle/quicktype_bundle.js")
  set(QT_PRELUDE   "${CMAKE_CURRENT_SOURCE_DIR}/bundle/prelude.js")
  set(QT_EMBED_PY  "${CMAKE_CURRENT_SOURCE_DIR}/shim/embed_bundle.py")
  set(QT_BUNDLE_C  "${CMAKE_CURRENT_BINARY_DIR}/bundle_data.c")

  find_package(Python3 REQUIRED COMPONENTS Interpreter)
  add_custom_command(
    OUTPUT  "${QT_BUNDLE_C}"
    COMMAND "${Python3_EXECUTABLE}" "${QT_EMBED_PY}"
            "${QT_PRELUDE}" "${QT_BUNDLE}" "${QT_BUNDLE_C}"
    DEPENDS "${QT_PRELUDE}" "${QT_BUNDLE}" "${QT_EMBED_PY}"
    COMMENT "Embedding quicktype JS bundle"
    VERBATIM
  )
  list(APPEND QT_SHIM_SOURCES "${QT_BUNDLE_C}")
else()
  message(STATUS "quicktype_dart: QT_EMBED_BUNDLE=OFF — bundle must be "
                 "supplied at runtime via BundleSource.remote")
endif()

# --- quicktype_dart shared library ---------------------------------------
# Named to match the pubspec `name`, which is what Flutter's platform build
# systems look for when embedding the plugin. Produces:
#   libquicktype_dart.so     (Linux / Android)
#   libquicktype_dart.dylib  (macOS / iOS, wrapped into a .framework by Pods)
#   quicktype_dart.dll       (Windows)
add_library(quicktype_dart SHARED ${QT_SHIM_SOURCES})
target_include_directories(quicktype_dart PRIVATE shim quickjs)
target_link_libraries(quicktype_dart PRIVATE qjs)
set_target_properties(quicktype_dart PROPERTIES
  C_VISIBILITY_PRESET hidden
  OUTPUT_NAME "quicktype_dart"
)
if(NOT QT_EMBED_BUNDLE)
  target_compile_definitions(quicktype_dart PRIVATE QT_NO_EMBEDDED_BUNDLE)
endif()

# On Apple platforms, use the explicit exports list so LTO doesn't eat our
# public symbols. Other platforms get the same effect via visibility("default")
# on QT_EXPORT-annotated declarations in shim/qt_shim.h.
if(APPLE)
  set_target_properties(quicktype_dart PROPERTIES
    LINK_FLAGS "-Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/shim/qt_shim.exports"
  )
endif()
