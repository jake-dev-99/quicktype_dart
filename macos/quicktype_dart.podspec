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
  s.version          = '0.4.6'
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
  s.platform = :osx, '10.14'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Include paths for the forwarded sources to resolve their includes.
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/../native/quickjs" "${PODS_TARGET_SRCROOT}/../native/shim"',
    # Silence quickjs-ng's expected warnings at -Wall without disabling them
    # across the consumer app.
    'OTHER_CFLAGS' => '-Wno-unused-parameter -Wno-implicit-fallthrough -Wno-sign-compare -Wno-unused-variable -Wno-unused-function',
  }
  s.swift_version = '5.0'
end
