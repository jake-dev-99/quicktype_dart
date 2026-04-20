// ignore_for_file: public_member_api_docs
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
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'wstring', wstring);
    putOpt(m, 'const-style', constStyle);
    putOpt(m, 'enum-type', enumType);
    putOpt(m, 'namespace', namespace);
    putOpt(m, 'code-format', codeFormat);
    putOpt(m, 'include-style', includeStyle);
    putOpt(m, 'source-style', sourceStyle);
    putOpt(m, 'boost', boost);
    putOpt(m, 'hide-null-optional', hideNullOptional);
    putOpt(m, 'type-style', typeStyle);
    putOpt(m, 'member-style', memberStyle);
    putOpt(m, 'enumerator-style', enumeratorStyle);
    return m;
  }
}
