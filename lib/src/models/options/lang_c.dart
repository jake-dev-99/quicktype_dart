// ignore_for_file: public_member_api_docs
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the C target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class CRendererOptions extends RendererOptions {
  const CRendererOptions({
    this.printStyle,
    this.hashtableSize,
    this.typedefAlias,
    this.sourceStyle,
    this.integerSize,
    this.typeStyle,
    this.memberStyle,
    this.enumeratorStyle,
  });

  final PrintStyle? printStyle;
  final String? hashtableSize;
  final TypedefAlias? typedefAlias;
  final SourceStyle? sourceStyle;
  final IntegerSize? integerSize;
  final NamingStyle? typeStyle;
  final NamingStyle? memberStyle;
  final NamingStyle? enumeratorStyle;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    putOpt(m, 'print-style', printStyle);
    putOpt(m, 'hashtable-size', hashtableSize);
    putOpt(m, 'typedef-alias', typedefAlias);
    putOpt(m, 'source-style', sourceStyle);
    putOpt(m, 'integer-size', integerSize);
    putOpt(m, 'type-style', typeStyle);
    putOpt(m, 'member-style', memberStyle);
    putOpt(m, 'enumerator-style', enumeratorStyle);
    return m;
  }
}
