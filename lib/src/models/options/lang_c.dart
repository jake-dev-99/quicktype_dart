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
    if (printStyle != null) m['print-style'] = printStyle!.toString();
    if (hashtableSize != null) m['hashtable-size'] = hashtableSize!;
    if (typedefAlias != null) m['typedef-alias'] = typedefAlias!.toString();
    if (sourceStyle != null) m['source-style'] = sourceStyle!.toString();
    if (integerSize != null) m['integer-size'] = integerSize!.toString();
    if (typeStyle != null) m['type-style'] = typeStyle!.toString();
    if (memberStyle != null) m['member-style'] = memberStyle!.toString();
    if (enumeratorStyle != null) {
      m['enumerator-style'] = enumeratorStyle!.toString();
    }
    return m;
  }
}
