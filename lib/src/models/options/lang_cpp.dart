import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Cpp target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
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

  final bool? justTypes;
  final WStringType? wstring;
  final ConstStyle? constStyle;
  final String? enumType;
  final String? namespace;
  final CodeFormat? codeFormat;
  final IncludeStyle? includeStyle;
  final SourceStyle? sourceStyle;
  final bool? boost;
  final bool? hideNullOptional;
  final NamingStyle? typeStyle;
  final NamingStyle? memberStyle;
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
    if (hideNullOptional != null)
      m['hide-null-optional'] = hideNullOptional.toString();
    if (typeStyle != null) m['type-style'] = typeStyle!.toString();
    if (memberStyle != null) m['member-style'] = memberStyle!.toString();
    if (enumeratorStyle != null)
      m['enumerator-style'] = enumeratorStyle!.toString();
    return m;
  }
}
