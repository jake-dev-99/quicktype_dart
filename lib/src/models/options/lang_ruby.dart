library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Ruby target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class RubyRendererOptions extends RendererOptions {
  const RubyRendererOptions({
    this.justTypes,
    this.strictness,
    this.namespace,
  });

  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--strictness` flag.
  final RubyStrictness? strictness;
  /// Maps to the `--namespace` flag.
  final String? namespace;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (strictness != null) m['strictness'] = strictness!.toString();
    if (namespace != null) m['namespace'] = namespace!;
    return m;
  }
}
