library;

import '../renderer_options.dart';

/// Named-parameter options for the Dart target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class DartRendererOptions extends RendererOptions {
  const DartRendererOptions({
    this.nullSafety,
    this.justTypes,
    this.codersInClass,
    this.fromMap,
    this.requiredProps,
    this.finalProps,
    this.copyWith,
    this.useFreezed,
    this.useHive,
    this.useJsonAnnotation,
    this.partName,
  });

  /// Maps to the `--null-safety` flag.
  final bool? nullSafety;
  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--coders-in-class` flag.
  final bool? codersInClass;
  /// Maps to the `--from-map` flag.
  final bool? fromMap;
  /// Maps to the `--required-props` flag.
  final bool? requiredProps;
  /// Maps to the `--final-props` flag.
  final bool? finalProps;
  /// Maps to the `--copy-with` flag.
  final bool? copyWith;
  /// Maps to the `--use-freezed` flag.
  final bool? useFreezed;
  /// Maps to the `--use-hive` flag.
  final bool? useHive;
  /// Maps to the `--use-json-annotation` flag.
  final bool? useJsonAnnotation;
  /// Maps to the `--part-name` flag.
  final String? partName;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (nullSafety != null) m['null-safety'] = nullSafety.toString();
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (codersInClass != null) m['coders-in-class'] = codersInClass.toString();
    if (fromMap != null) m['from-map'] = fromMap.toString();
    if (requiredProps != null) m['required-props'] = requiredProps.toString();
    if (finalProps != null) m['final-props'] = finalProps.toString();
    if (copyWith != null) m['copy-with'] = copyWith.toString();
    if (useFreezed != null) m['use-freezed'] = useFreezed.toString();
    if (useHive != null) m['use-hive'] = useHive.toString();
    if (useJsonAnnotation != null) m['use-json-annotation'] = useJsonAnnotation.toString();
    if (partName != null) m['part-name'] = partName!;
    return m;
  }
}
