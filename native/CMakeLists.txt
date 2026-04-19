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
project(qt_shim LANGUAGES C)

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

# --- Embed the JS bundle + prelude as C arrays ----------------------------
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

# --- qt_shim shared library ----------------------------------------------
add_library(qt_shim SHARED
  shim/qt_shim.c
  "${QT_BUNDLE_C}"
)
target_include_directories(qt_shim PRIVATE shim quickjs)
target_link_libraries(qt_shim PRIVATE qjs)
set_target_properties(qt_shim PROPERTIES
  C_VISIBILITY_PRESET hidden
  OUTPUT_NAME "qt_shim"
)

# On macOS, mark symbols used by the Dart plugin so they survive LTO.
if(APPLE)
  set_target_properties(qt_shim PROPERTIES
    LINK_FLAGS "-Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/shim/qt_shim.exports"
  )
endif()
