// ignore_for_file: public_member_api_docs
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Elm target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class ElmRendererOptions extends RendererOptions {
  const ElmRendererOptions({
    this.justTypes,
    this.module,
    this.arrayType,
  });

  final bool? justTypes;
  final String? module;
  final ArrayType? arrayType;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'module', module);
    putOpt(m, 'array-type', arrayType);
    return m;
  }
}
