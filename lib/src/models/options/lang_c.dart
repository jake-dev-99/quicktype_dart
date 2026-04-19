library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the C target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
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

  /// Maps to the `--print-style` flag.
  final PrintStyle? printStyle;
  /// Maps to the `--hashtable-size` flag.
  final String? hashtableSize;
  /// Maps to the `--typedef-alias` flag.
  final TypedefAlias? typedefAlias;
  /// Maps to the `--source-style` flag.
  final SourceStyle? sourceStyle;
  /// Maps to the `--integer-size` flag.
  final IntegerSize? integerSize;
  /// Maps to the `--type-style` flag.
  final NamingStyle? typeStyle;
  /// Maps to the `--member-style` flag.
  final NamingStyle? memberStyle;
  /// Maps to the `--enumerator-style` flag.
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
    if (enumeratorStyle != null) m['enumerator-style'] = enumeratorStyle!.toString();
    return m;
  }
}
