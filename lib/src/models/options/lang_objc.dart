// ignore_for_file: public_member_api_docs
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
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'class-prefix', classPrefix);
    putOpt(m, 'features', features);
    putOpt(m, 'extra-comments', extraComments);
    putOpt(m, 'functions', functions);
    return m;
  }
}
