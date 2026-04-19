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
/// QuicktypeDart.setBundleSource(BundleSource.remote(
///   Uri.parse('https://cdn.example.com/quicktype_bundle.js'),
///   integrity: 'sha384-…',  // optional Subresource Integrity hash
/// ));
///
/// // Subsequent calls use the remote bundle.
/// await QuicktypeDart.generate(label: 'User', data: ..., target: TargetType.dart);
/// ```
///
/// **Platform coverage in v0.3.0:** Flutter Web honors both [embedded] and
/// [remote]. Native targets (macOS / iOS / Linux / Windows / Android) always
/// use the embedded QuickJS bundle regardless of this setting — remote
/// bundle support on native ships in v0.3.1.
sealed class BundleSource {
  const BundleSource();

  /// The default — loads the bundle shipped with this package as a
  /// Flutter plugin asset.
  const factory BundleSource.embedded() = EmbeddedBundleSource;

  /// Load the bundle from [url]. On Flutter Web, injects a `<script>` tag
  /// with the URL. Pass [integrity] to have the browser enforce a
  /// Subresource Integrity hash (e.g. `'sha384-…'`) — strongly recommended
  /// for third-party CDNs.
  const factory BundleSource.remote(Uri url, {String? integrity}) =
      RemoteBundleSource;
}

/// See [BundleSource.embedded].
final class EmbeddedBundleSource extends BundleSource {
  const EmbeddedBundleSource();
}

/// See [BundleSource.remote].
final class RemoteBundleSource extends BundleSource {
  const RemoteBundleSource(this.url, {this.integrity});

  /// Absolute URL the browser will `<script src="…">` load from.
  final Uri url;

  /// Optional Subresource Integrity hash (e.g. `'sha384-…'`).
  final String? integrity;
}
