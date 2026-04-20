// ignore_for_file: public_member_api_docs
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Ruby target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class RubyRendererOptions extends RendererOptions {
  const RubyRendererOptions({
    this.justTypes,
    this.strictness,
    this.namespace,
  });

  final bool? justTypes;
  final RubyStrictness? strictness;
  final String? namespace;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'strictness', strictness);
    putOpt(m, 'namespace', namespace);
    return m;
  }
}
