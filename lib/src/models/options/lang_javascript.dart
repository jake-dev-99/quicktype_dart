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
    if (copyAccessorAnnotations != null) {
      m['copy-accessor-annotations'] = copyAccessorAnnotations.toString();
    }
    if (runtimeTypecheck != null) {
      m['runtime-typecheck'] = runtimeTypecheck.toString();
    }
    if (runtimeTypecheckIgnoreUnknownProperties != null) {
      m['runtime-typecheck-ignore-unknown-properties'] =
          runtimeTypecheckIgnoreUnknownProperties.toString();
    }
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (converters != null) m['converters'] = converters!.toString();
    if (rawType != null) m['raw-type'] = rawType!.toString();
    return m;
  }
}
