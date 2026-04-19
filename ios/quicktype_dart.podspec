#
# CocoaPods spec for the quicktype_dart iOS Flutter FFI plugin.
#
# Structure mirrors macos/quicktype_dart.podspec — Classes/*.c files
# forward-include the shared sources at ../native/. Builds a
# quicktype_dart.framework that ships in the iOS app bundle.
#

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

  s.dependency 'Flutter'
  # iOS 13 is the floor Apple's current Xcode/Flutter combos realistically
  # support. Bumped from iOS 12 in v0.4.3.
  s.platform = :ios, '13.0'

  # Silence the quickjs-ng warnings we can't fix without patching upstream.
  # These match what native/CMakeLists.txt applies to the qjs target.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Flutter.framework doesn't contain an i386 slice.
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/../native/quickjs" "${PODS_TARGET_SRCROOT}/../native/shim"',
    'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'NO',
    'OTHER_CFLAGS' => '-Wno-implicit-fallthrough -Wno-sign-compare',
  }
  s.swift_version = '5.0'
end
