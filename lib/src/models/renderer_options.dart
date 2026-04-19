/// Base interface for named-parameter language options passed to
/// [QuicktypeDart.generate] via `options:`.
///
/// Each target language has a concrete subclass under
/// `lib/src/models/options/lang_*.dart` — e.g. [DartRendererOptions],
/// [KotlinRendererOptions], [SwiftRendererOptions]. Construct one and pass
/// it directly:
///
/// ```dart
/// await QuicktypeDart.generate(
///   label: 'User',
///   data: {'id': 1, 'name': 'Jake'},
///   target: TargetType.dart,
///   options: const DartRendererOptions(
///     useFreezed: true,
///     nullSafety: true,
///   ),
/// );
/// ```
///
/// The older `Arg`-list API (`args: [DartArgs.useFreezed..value = true]`)
/// is still supported but deprecated — the typed options classes provide
/// compile-time field names + IDE autocomplete for every flag the
/// underlying renderer accepts.
abstract class RendererOptions {
  const RendererOptions();

  /// Serializes this options instance to the `Map<String, String>` shape
  /// quicktype-core's `rendererOptions` accepts. Only non-null fields are
  /// included.
  Map<String, String> toRendererOptions();
}
