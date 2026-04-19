library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the PHP target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class PHPRendererOptions extends RendererOptions {
  const PHPRendererOptions({
    this.withGet,
    this.fastGet,
    this.withSet,
    this.withClosing,
    this.acronymStyle,
  });

  /// Maps to the `--with-get` flag.
  final bool? withGet;
  /// Maps to the `--fast-get` flag.
  final bool? fastGet;
  /// Maps to the `--with-set` flag.
  final bool? withSet;
  /// Maps to the `--with-closing` flag.
  final bool? withClosing;
  /// Maps to the `--acronym-style` flag.
  final AcronymStyle? acronymStyle;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (withGet != null) m['with-get'] = withGet.toString();
    if (fastGet != null) m['fast-get'] = fastGet.toString();
    if (withSet != null) m['with-set'] = withSet.toString();
    if (withClosing != null) m['with-closing'] = withClosing.toString();
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    return m;
  }
}
