// ignore_for_file: public_member_api_docs
import '../renderer_options.dart';

/// Named-parameter options for the Dart target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
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

  final bool? nullSafety;
  final bool? justTypes;
  final bool? codersInClass;
  final bool? fromMap;
  final bool? requiredProps;
  final bool? finalProps;
  final bool? copyWith;
  final bool? useFreezed;
  final bool? useHive;
  final bool? useJsonAnnotation;
  final String? partName;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    putOpt(m, 'null-safety', nullSafety);
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'coders-in-class', codersInClass);
    putOpt(m, 'from-map', fromMap);
    putOpt(m, 'required-props', requiredProps);
    putOpt(m, 'final-props', finalProps);
    putOpt(m, 'copy-with', copyWith);
    putOpt(m, 'use-freezed', useFreezed);
    putOpt(m, 'use-hive', useHive);
    putOpt(m, 'use-json-annotation', useJsonAnnotation);
    putOpt(m, 'part-name', partName);
    return m;
  }
}
