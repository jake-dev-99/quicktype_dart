// ignore_for_file: public_member_api_docs
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the PHP target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class PHPRendererOptions extends RendererOptions {
  const PHPRendererOptions({
    this.withGet,
    this.fastGet,
    this.withSet,
    this.withClosing,
    this.acronymStyle,
  });

  final bool? withGet;
  final bool? fastGet;
  final bool? withSet;
  final bool? withClosing;
  final AcronymStyle? acronymStyle;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    putOpt(m, 'with-get', withGet);
    putOpt(m, 'fast-get', fastGet);
    putOpt(m, 'with-set', withSet);
    putOpt(m, 'with-closing', withClosing);
    putOpt(m, 'acronym-style', acronymStyle);
    return m;
  }
}
