library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the ObjectiveC target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class ObjectiveCRendererOptions extends RendererOptions {
  const ObjectiveCRendererOptions({
    this.justTypes,
    this.classPrefix,
    this.features,
    this.extraComments,
    this.functions,
  });

  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--class-prefix` flag.
  final String? classPrefix;
  /// Maps to the `--features` flag.
  final ObjectiveCFeatures? features;
  /// Maps to the `--extra-comments` flag.
  final bool? extraComments;
  /// Maps to the `--functions` flag.
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
