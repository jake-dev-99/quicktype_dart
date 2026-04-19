# Flutter Linux desktop FFI plugin entry point.
#
# Flutter invokes this CMake during `flutter build linux`. We delegate the
# actual compile to the shared `native/` tree so macOS, Linux, Windows, and
# Android all build from the same sources.
#
# The Flutter tooling requires CMake ≥ 3.10.

cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "quicktype_dart")
project(${PROJECT_NAME} LANGUAGES C)

# Build the shared `native/` tree. Produces the `quicktype_dart` shared
# library target (libquicktype_dart.so on Linux).
add_subdirectory(
  "${CMAKE_CURRENT_SOURCE_DIR}/../native"
  "${CMAKE_CURRENT_BINARY_DIR}/shared"
)

# Expose the built library so Flutter bundles it into the app's output.
# The Flutter tool looks for this specific variable in scope.
set(quicktype_dart_bundled_libraries
  $<TARGET_FILE:quicktype_dart>
  PARENT_SCOPE
)
