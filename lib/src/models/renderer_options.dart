import '../config.dart' show ConfigException;

/// Normalizes raw key/value pairs (from `quicktype.json` or the
/// `build.yaml` `args:` block) into the `Map<String, String>` shape
/// quicktype-core expects.
///
/// Accepts `bool`, `String`, or `null` (skipped). Anything else throws
/// [ConfigException] so typos like `use-freezed: 1` or
/// `part-name: [foo]` fail loud at config-load time instead of silently
/// coercing via `toString()` and producing mystery output.
///
/// Used by both `TypeConfig.fromJson` (config-driven flow) and the
/// `quicktype_dart` builder in `lib/entrypoint_runner.dart`. Keeping a
/// single implementation avoids the surprise of `quicktype.json`
/// rejecting a value that `build.yaml` would silently accept.
///
/// [sectionLabel] is included verbatim in error messages (e.g.
/// `'target "dart"'`) so the caller can pinpoint which config slot
/// produced the bad entry.
Map<String, String> coerceRendererOptionsMap(
  Map<String, Object?> raw, {
  String sectionLabel = 'renderer options',
}) {
  final out = <String, String>{};
  for (final entry in raw.entries) {
    final v = entry.value;
    if (v == null) continue;
    if (v is bool) {
      out[entry.key] = v.toString();
    } else if (v is String) {
      out[entry.key] = v;
    } else {
      throw ConfigException(
        '$sectionLabel: renderer option "${entry.key}" has unsupported '
        'value type ${v.runtimeType} (value: $v). Expected bool, '
        'String, or null.',
      );
    }
  }
  return out;
}

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
  const RendererOptions();

  /// Serializes this options instance to the `Map<String, String>` shape
  /// quicktype-core's `rendererOptions` accepts. Only non-null fields are
  /// included.
  Map<String, String> toRendererOptions();
}
