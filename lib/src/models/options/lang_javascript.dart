library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the JavaScript target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class JavaScriptRendererOptions extends RendererOptions {
  const JavaScriptRendererOptions({
    this.copyAccessorAnnotations,
    this.runtimeTypecheck,
    this.runtimeTypecheckIgnoreUnknownProperties,
    this.acronymStyle,
    this.converters,
    this.rawType,
  });

  /// Maps to the `--copy-accessor-annotations` flag.
  final bool? copyAccessorAnnotations;
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

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (copyAccessorAnnotations != null) m['copy-accessor-annotations'] = copyAccessorAnnotations.toString();
    if (runtimeTypecheck != null) m['runtime-typecheck'] = runtimeTypecheck.toString();
    if (runtimeTypecheckIgnoreUnknownProperties != null) m['runtime-typecheck-ignore-unknown-properties'] = runtimeTypecheckIgnoreUnknownProperties.toString();
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (converters != null) m['converters'] = converters!.toString();
    if (rawType != null) m['raw-type'] = rawType!.toString();
    return m;
  }
}
