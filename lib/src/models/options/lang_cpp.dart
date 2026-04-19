library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Cpp target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class CppRendererOptions extends RendererOptions {
  const CppRendererOptions({
    this.justTypes,
    this.wstring,
    this.constStyle,
    this.enumType,
    this.namespace,
    this.codeFormat,
    this.includeStyle,
    this.sourceStyle,
    this.boost,
    this.hideNullOptional,
    this.typeStyle,
    this.memberStyle,
    this.enumeratorStyle,
  });

  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--wstring` flag.
  final WStringType? wstring;
  /// Maps to the `--const-style` flag.
  final ConstStyle? constStyle;
  /// Maps to the `--enum-type` flag.
  final String? enumType;
  /// Maps to the `--namespace` flag.
  final String? namespace;
  /// Maps to the `--code-format` flag.
  final CodeFormat? codeFormat;
  /// Maps to the `--include-style` flag.
  final IncludeStyle? includeStyle;
  /// Maps to the `--source-style` flag.
  final SourceStyle? sourceStyle;
  /// Maps to the `--boost` flag.
  final bool? boost;
  /// Maps to the `--hide-null-optional` flag.
  final bool? hideNullOptional;
  /// Maps to the `--type-style` flag.
  final NamingStyle? typeStyle;
  /// Maps to the `--member-style` flag.
  final NamingStyle? memberStyle;
  /// Maps to the `--enumerator-style` flag.
  final NamingStyle? enumeratorStyle;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (wstring != null) m['wstring'] = wstring!.toString();
    if (constStyle != null) m['const-style'] = constStyle!.toString();
    if (enumType != null) m['enum-type'] = enumType!;
    if (namespace != null) m['namespace'] = namespace!;
    if (codeFormat != null) m['code-format'] = codeFormat!.toString();
    if (includeStyle != null) m['include-style'] = includeStyle!.toString();
    if (sourceStyle != null) m['source-style'] = sourceStyle!.toString();
    if (boost != null) m['boost'] = boost.toString();
    if (hideNullOptional != null) m['hide-null-optional'] = hideNullOptional.toString();
    if (typeStyle != null) m['type-style'] = typeStyle!.toString();
    if (memberStyle != null) m['member-style'] = memberStyle!.toString();
    if (enumeratorStyle != null) m['enumerator-style'] = enumeratorStyle!.toString();
    return m;
  }
}
