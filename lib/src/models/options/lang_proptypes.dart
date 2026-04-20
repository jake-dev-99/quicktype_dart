// ignore_for_file: public_member_api_docs
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the PropTypes target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class PropTypesRendererOptions extends RendererOptions {
  const PropTypesRendererOptions({
    this.acronymStyle,
    this.converters,
  });

  final AcronymStyle? acronymStyle;
  final ConverterType? converters;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    putOpt(m, 'acronym-style', acronymStyle);
    putOpt(m, 'converters', converters);
    return m;
  }
}
