import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the TypeScript target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class TypeScriptRendererOptions extends RendererOptions {
  const TypeScriptRendererOptions({
    this.justTypes,
    this.nicePropertyNames,
    this.explicitUnions,
    this.runtimeTypecheck,
    this.runtimeTypecheckIgnoreUnknownProperties,
    this.acronymStyle,
    this.converters,
    this.rawType,
    this.preferUnions,
    this.preferTypes,
    this.preferConstValues,
    this.readonly,
  });

  final bool? justTypes;
  final bool? nicePropertyNames;
  final bool? explicitUnions;
  final bool? runtimeTypecheck;
  final bool? runtimeTypecheckIgnoreUnknownProperties;
  final AcronymStyle? acronymStyle;
  final ConverterType? converters;
  final RawType? rawType;
  final bool? preferUnions;
  final bool? preferTypes;
  final bool? preferConstValues;
  final bool? readonly;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (nicePropertyNames != null)
      m['nice-property-names'] = nicePropertyNames.toString();
    if (explicitUnions != null)
      m['explicit-unions'] = explicitUnions.toString();
    if (runtimeTypecheck != null)
      m['runtime-typecheck'] = runtimeTypecheck.toString();
    if (runtimeTypecheckIgnoreUnknownProperties != null)
      m['runtime-typecheck-ignore-unknown-properties'] =
          runtimeTypecheckIgnoreUnknownProperties.toString();
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (converters != null) m['converters'] = converters!.toString();
    if (rawType != null) m['raw-type'] = rawType!.toString();
    if (preferUnions != null) m['prefer-unions'] = preferUnions.toString();
    if (preferTypes != null) m['prefer-types'] = preferTypes.toString();
    if (preferConstValues != null)
      m['prefer-const-values'] = preferConstValues.toString();
    if (readonly != null) m['readonly'] = readonly.toString();
    return m;
  }
}
