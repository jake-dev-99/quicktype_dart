# Flutter Windows desktop FFI plugin entry point.
#
# Invoked during `flutter build windows`. Delegates to the shared native/
# tree so all platforms build from the same sources.
#
# Visual Studio's CMake requires ≥ 3.14.

cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "quicktype_dart")
project(${PROJECT_NAME} LANGUAGES C)

# Silence MSVC's noisiest C warnings from quickjs-ng — these are expected
# in that codebase and not actionable in our consumption of it.
if(MSVC)
  add_compile_options(/wd4101 /wd4146 /wd4244 /wd4267 /wd4305 /wd4334)
  add_compile_definitions(_CRT_SECURE_NO_WARNINGS _CRT_NONSTDC_NO_WARNINGS)
endif()

add_subdirectory(
  "${CMAKE_CURRENT_SOURCE_DIR}/../native"
  "${CMAKE_CURRENT_BINARY_DIR}/shared"
)

set(quicktype_dart_bundled_libraries
  $<TARGET_FILE:quicktype_dart>
  PARENT_SCOPE
)
