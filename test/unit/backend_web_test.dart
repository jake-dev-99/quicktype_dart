@TestOn('browser')
library;

import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:test/test.dart';

/// Smoke-level coverage for the web backend — proves the conditional
/// import wires up correctly and the public [QuicktypeDart] surface is
/// reachable on a browser platform.
///
/// End-to-end bundle-loading behavior is exercised by the
/// `example/` build_runner flow (see Batch G.5 for the CI matrix that
/// wires that up); pure-browser unit tests keep to surface-level
/// assertions that don't require a real bundle.
void main() {
  group('web backend wiring', () {
    test('GenerateTransport.ffi throws UnsupportedError on web', () async {
      expect(
        () => QuicktypeDart.generateFromString(
          label: 'User',
          json: '{}',
          target: TargetType.dart,
          transport: GenerateTransport.ffi,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('GenerateTransport.process throws UnsupportedError on web', () async {
      expect(
        () => QuicktypeDart.generateFromString(
          label: 'User',
          json: '{}',
          target: TargetType.dart,
          transport: GenerateTransport.process,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('QuicktypeDart.bundleSource defaults to embedded', () {
      expect(QuicktypeDart.bundleSource, isA<EmbeddedBundleSource>());
      expect(QuicktypeDart.bundleSource, same(const BundleSource.embedded()));
    });
  });
}
