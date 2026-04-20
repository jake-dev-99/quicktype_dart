// ignore_for_file: public_member_api_docs
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Flow target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
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
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'nice-property-names', nicePropertyNames);
    putOpt(m, 'explicit-unions', explicitUnions);
    putOpt(m, 'runtime-typecheck', runtimeTypecheck);
    putOpt(m, 'runtime-typecheck-ignore-unknown-properties',
        runtimeTypecheckIgnoreUnknownProperties);
    putOpt(m, 'acronym-style', acronymStyle);
    putOpt(m, 'converters', converters);
    putOpt(m, 'raw-type', rawType);
    putOpt(m, 'prefer-unions', preferUnions);
    putOpt(m, 'prefer-types', preferTypes);
    putOpt(m, 'prefer-const-values', preferConstValues);
    putOpt(m, 'readonly', readonly);
    return m;
  }
}
