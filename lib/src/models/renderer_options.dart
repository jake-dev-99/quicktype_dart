import '../config.dart' show ConfigException;

/// Normalizes raw key/value pairs (from `quicktype.json` or the
/// `build.yaml` `args:` block) into the `Map<String, String>` shape
/// quicktype-core expects.
///
/// Accepts `bool`, `String`, `num` (stringified), or `null` (skipped).
/// Anything else — lists, maps, DateTimes — throws [ConfigException]
/// with a hint. Silent `toString()` coercion of arbitrary objects is
/// avoided so typos like `args: { framework: [foo] }` fail at
/// config-load time instead of producing mystery CLI flags.
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
    if (v is bool || v is String || v is num) {
      out[entry.key] = v.toString();
    } else {
      throw ConfigException(
        '$sectionLabel: renderer option "${entry.key}" has unsupported '
        'value type ${v.runtimeType} (value: $v). Expected bool, String, '
        'num, or null. If you need a free-form value, stringify it at '
        'the call site.',
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
///
/// For programmatic callers that already have a raw `Map<String, String>`
/// (e.g. the `build_runner` builder tunneling `args:` from YAML), use
/// [RendererOptions.raw] instead of picking a language-specific subclass.
abstract class RendererOptions {
  /// Subclass constructor hook. Concrete languages expose their own
  /// typed constructor (`DartRendererOptions`, etc.).
  const RendererOptions();

  /// Wraps an already-built renderer-options map. Keys are
  /// quicktype-core option names (kebab-case); values are stringified
  /// (`'true'`/`'false'`/verbatim string). Use this when the map comes
  /// from a source that already matches quicktype-core's shape.
  const factory RendererOptions.raw(Map<String, String> options) =
      _RawRendererOptions;

  /// Serializes this options instance to the `Map<String, String>` shape
  /// quicktype-core's `rendererOptions` accepts. Only non-null fields are
  /// included.
  Map<String, String> toRendererOptions();
}

class _RawRendererOptions extends RendererOptions {
  const _RawRendererOptions(this._map);
  final Map<String, String> _map;

  @override
  Map<String, String> toRendererOptions() => _map;
}

/// Assigns `value.toString()` to [into] under [key] when [value] is
/// non-null. Used by every `*RendererOptions.toRendererOptions()` to
/// collapse the repeated null-check + toString pattern into one line.
///
/// Package-private. Exposed to subclasses in lib/src/models/options/
/// via a regular import.
void putOpt(Map<String, String> into, String key, Object? value) {
  if (value == null) return;
  into[key] = value.toString();
}
