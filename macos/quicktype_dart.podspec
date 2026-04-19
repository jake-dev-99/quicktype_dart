#
# CocoaPods spec for the quicktype_dart macOS Flutter FFI plugin.
#
# Compiles QuickJS-NG + the qt_shim bridge + the embedded JS bundle
# into a dynamic framework loaded from Dart via FFI.
#
# The native C sources live at `<plugin-root>/native/`. CocoaPods
# forbids source_files outside the podspec dir, so `Classes/*.c`
# contains forwarder files that relatively `#include` from `../native/`.

Pod::Spec.new do |s|
  s.name             = 'quicktype_dart'
  s.version          = '0.4.3'
  s.summary          = 'Cross-platform type generation from JSON.'
  s.description      = <<-DESC
    Embeds quicktype-core inside a QuickJS-NG runtime via FFI so Flutter
    apps can generate typed models from JSON without a Node CLI at runtime.
  DESC
  s.homepage         = 'https://github.com/jake-dev-99/quicktype_dart'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jake Allen' => 'jake@simplezen.io' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{c,h}'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'FlutterMacOS'
  # macOS 10.15 (Catalina) is the floor Apple's current SDK tooling ships
  # with. Bumped from 10.14 in v0.4.3.
  s.platform = :osx, '10.15'

  # Silence the quickjs-ng warnings we can't fix without patching upstream.
  # These match what native/CMakeLists.txt applies to the qjs target;
  # -Wno-unused-variable / -Wno-unused-function are covered by the shim
  # target's compile options, not repeated here.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Include paths for the forwarded sources to resolve their includes.
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/../native/quickjs" "${PODS_TARGET_SRCROOT}/../native/shim"',
    'OTHER_CFLAGS' => '-Wno-implicit-fallthrough -Wno-sign-compare',
  }
  s.swift_version = '5.0'
end
