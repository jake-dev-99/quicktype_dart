
library;

import '../renderer_options.dart';

/// Named-parameter options for the Elixir target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class ElixirRendererOptions extends RendererOptions {
  const ElixirRendererOptions({
    this.justTypes,
    this.namespace,
  });

  final bool? justTypes;
  final String? namespace;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (namespace != null) m['namespace'] = namespace!;
    return m;
  }
}
