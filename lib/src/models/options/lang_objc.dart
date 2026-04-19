
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the ObjectiveC target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class ObjectiveCRendererOptions extends RendererOptions {
  const ObjectiveCRendererOptions({
    this.justTypes,
    this.classPrefix,
    this.features,
    this.extraComments,
    this.functions,
  });

  final bool? justTypes;
  final String? classPrefix;
  final ObjectiveCFeatures? features;
  final bool? extraComments;
  final bool? functions;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (classPrefix != null) m['class-prefix'] = classPrefix!;
    if (features != null) m['features'] = features!.toString();
    if (extraComments != null) m['extra-comments'] = extraComments.toString();
    if (functions != null) m['functions'] = functions.toString();
    return m;
  }
}
