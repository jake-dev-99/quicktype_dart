// ignore_for_file: public_member_api_docs
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
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'namespace', namespace);
    return m;
  }
}
