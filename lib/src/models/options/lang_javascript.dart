// ignore_for_file: public_member_api_docs
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the JavaScript target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class JavaScriptRendererOptions extends RendererOptions {
  const JavaScriptRendererOptions({
    this.copyAccessorAnnotations,
    this.runtimeTypecheck,
    this.runtimeTypecheckIgnoreUnknownProperties,
    this.acronymStyle,
    this.converters,
    this.rawType,
  });

  final bool? copyAccessorAnnotations;
  final bool? runtimeTypecheck;
  final bool? runtimeTypecheckIgnoreUnknownProperties;
  final AcronymStyle? acronymStyle;
  final ConverterType? converters;
  final RawType? rawType;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    putOpt(m, 'copy-accessor-annotations', copyAccessorAnnotations);
    putOpt(m, 'runtime-typecheck', runtimeTypecheck);
    putOpt(m, 'runtime-typecheck-ignore-unknown-properties',
        runtimeTypecheckIgnoreUnknownProperties);
    putOpt(m, 'acronym-style', acronymStyle);
    putOpt(m, 'converters', converters);
    putOpt(m, 'raw-type', rawType);
    return m;
  }
}
