/// Base interface for named-parameter language options passed to
/// [QuicktypeDart.generate] via `options:`.
///
/// Each target language has a concrete subclass under
/// `lib/src/models/options/lang_*.dart` — e.g. `DartRendererOptions`,
/// `KotlinRendererOptions`, `SwiftRendererOptions`. Construct one and pass
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
/// Null-valued fields are omitted from the serialized output, so any
/// option you don't explicitly set inherits quicktype-core's default.
abstract class RendererOptions {
  /// Subclass constructor hook. Concrete languages expose their own
  /// typed constructor (`DartRendererOptions`, etc.).
  const RendererOptions();

  /// Serializes this options instance to the `Map<String, String>` shape
  /// quicktype-core's `rendererOptions` accepts. Only non-null fields are
  /// included.
  Map<String, String> toRendererOptions();
}
