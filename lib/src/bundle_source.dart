/// Where the Flutter Web backend should load the quicktype-core JS bundle
/// from.
///
/// Default is [BundleSource.embedded], which ships the 2.9MB bundle as a
/// Flutter plugin asset at `packages/quicktype_dart/assets/quicktype_bundle.js`.
/// Apps that prefer not to bundle it can switch to [BundleSource.remote]
/// to load from a CDN instead — typically saves ~2.8MB off the published
/// web artifact.
///
/// ```dart
/// QuicktypeDart.bundleSource = BundleSource.remote(
///   Uri.parse('https://cdn.example.com/quicktype_bundle.js'),
///   integrity: 'sha384-…',  // optional Subresource Integrity hash
/// );
///
/// // Subsequent calls use the remote bundle.
/// await QuicktypeDart.generate(label: 'User', data: ..., target: TargetType.dart);
/// ```
///
/// **Platform coverage:** Both Flutter Web and native targets (macOS / iOS
/// / Linux / Windows / Android) honor [embedded] and [remote]. On native,
/// remote bundles are fetched once via `dart:io` `HttpClient`, cached
/// on-disk under the system temp dir keyed by URL hash, and loaded into
/// the QuickJS runtime. Pass [RemoteBundleSource.integrity] for
/// Subresource-Integrity verification (SHA-256/384/512).
///
/// Pair `BundleSource.remote` with a native library built using
/// `-DQT_NO_EMBEDDED_BUNDLE` (or `cmake -DQT_EMBED_BUNDLE=OFF`) to shed
/// the ~2.9MB embedded bundle from the final binary.
sealed class BundleSource {
  const BundleSource();

  /// The default — loads the bundle shipped with this package as a
  /// Flutter plugin asset.
  const factory BundleSource.embedded() = EmbeddedBundleSource;

  /// Load the bundle from [url].
  ///
  /// On Flutter Web, injects a `<script>` tag with the URL; the browser
  /// enforces [integrity] natively.
  ///
  /// On native, the bytes are fetched, cached on-disk, and verified
  /// against [integrity] (SRI-format: `'sha256-…'`, `'sha384-…'`, or
  /// `'sha512-…'`) before being handed to the QuickJS runtime.
  ///
  /// Passing [integrity] is strongly recommended for third-party CDNs.
  const factory BundleSource.remote(Uri url, {String? integrity}) =
      RemoteBundleSource;
}

/// See [BundleSource.embedded].
final class EmbeddedBundleSource extends BundleSource {
  /// Creates a [BundleSource] that loads the compiled-in bundle. Use
  /// the [BundleSource.embedded] factory for clarity.
  const EmbeddedBundleSource();
}

/// See [BundleSource.remote].
final class RemoteBundleSource extends BundleSource {
  /// Creates a [BundleSource] that fetches from [url], optionally
  /// verified against a Subresource-Integrity [integrity] token. Use
  /// the [BundleSource.remote] factory for clarity.
  const RemoteBundleSource(this.url, {this.integrity});

  /// Absolute URL the browser will `<script src="…">` load from.
  final Uri url;

  /// Optional Subresource Integrity hash (e.g. `'sha384-…'`).
  final String? integrity;
}
