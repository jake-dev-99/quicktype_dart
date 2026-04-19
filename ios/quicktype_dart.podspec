#
# CocoaPods spec for the quicktype_dart iOS Flutter FFI plugin.
#
# Structure mirrors macos/quicktype_dart.podspec — Classes/*.c files
# forward-include the shared sources at ../native/. Builds a
# quicktype_dart.framework that ships in the iOS app bundle.
#

Pod::Spec.new do |s|
  s.name             = 'quicktype_dart'
  s.version          = '0.6.0'
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
  s.platform = :ios, '12.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Flutter.framework doesn't contain an i386 slice.
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/../native/quickjs" "${PODS_TARGET_SRCROOT}/../native/shim"',
    'OTHER_CFLAGS' => '-Wno-unused-parameter -Wno-implicit-fallthrough -Wno-sign-compare -Wno-unused-variable -Wno-unused-function',
  }
  s.swift_version = '5.0'
end
