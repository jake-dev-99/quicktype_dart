library;

import '../renderer_options.dart';

/// Named-parameter options for the Elixir target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class ElixirRendererOptions extends RendererOptions {
  const ElixirRendererOptions({
    this.justTypes,
    this.namespace,
  });

  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--namespace` flag.
  final String? namespace;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (namespace != null) m['namespace'] = namespace!;
    return m;
  }
}
