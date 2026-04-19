library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the PropTypes target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class PropTypesRendererOptions extends RendererOptions {
  const PropTypesRendererOptions({
    this.acronymStyle,
    this.converters,
  });

  /// Maps to the `--acronym-style` flag.
  final AcronymStyle? acronymStyle;
  /// Maps to the `--converters` flag.
  final ConverterType? converters;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (converters != null) m['converters'] = converters!.toString();
    return m;
  }
}
