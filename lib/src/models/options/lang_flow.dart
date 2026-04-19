library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Flow target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class FlowRendererOptions extends RendererOptions {
  const FlowRendererOptions({
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

  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--nice-property-names` flag.
  final bool? nicePropertyNames;
  /// Maps to the `--explicit-unions` flag.
  final bool? explicitUnions;
  /// Maps to the `--runtime-typecheck` flag.
  final bool? runtimeTypecheck;
  /// Maps to the `--runtime-typecheck-ignore-unknown-properties` flag.
  final bool? runtimeTypecheckIgnoreUnknownProperties;
  /// Maps to the `--acronym-style` flag.
  final AcronymStyle? acronymStyle;
  /// Maps to the `--converters` flag.
  final ConverterType? converters;
  /// Maps to the `--raw-type` flag.
  final RawType? rawType;
  /// Maps to the `--prefer-unions` flag.
  final bool? preferUnions;
  /// Maps to the `--prefer-types` flag.
  final bool? preferTypes;
  /// Maps to the `--prefer-const-values` flag.
  final bool? preferConstValues;
  /// Maps to the `--readonly` flag.
  final bool? readonly;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (nicePropertyNames != null) m['nice-property-names'] = nicePropertyNames.toString();
    if (explicitUnions != null) m['explicit-unions'] = explicitUnions.toString();
    if (runtimeTypecheck != null) m['runtime-typecheck'] = runtimeTypecheck.toString();
    if (runtimeTypecheckIgnoreUnknownProperties != null) m['runtime-typecheck-ignore-unknown-properties'] = runtimeTypecheckIgnoreUnknownProperties.toString();
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (converters != null) m['converters'] = converters!.toString();
    if (rawType != null) m['raw-type'] = rawType!.toString();
    if (preferUnions != null) m['prefer-unions'] = preferUnions.toString();
    if (preferTypes != null) m['prefer-types'] = preferTypes.toString();
    if (preferConstValues != null) m['prefer-const-values'] = preferConstValues.toString();
    if (readonly != null) m['readonly'] = readonly.toString();
    return m;
  }
}
