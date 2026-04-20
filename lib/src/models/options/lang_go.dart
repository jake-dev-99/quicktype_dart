// ignore_for_file: public_member_api_docs
import '../renderer_options.dart';

/// Named-parameter options for the Go target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class GoRendererOptions extends RendererOptions {
  const GoRendererOptions({
    this.justTypes,
    this.justTypesAndPackage,
    this.package,
    this.multiFileTarget,
    this.fieldTags,
    this.omitEmpty,
  });

  final bool? justTypes;
  final bool? justTypesAndPackage;
  final String? package;
  final bool? multiFileTarget;
  final String? fieldTags;
  final bool? omitEmpty;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'just-types-and-package', justTypesAndPackage);
    putOpt(m, 'package', package);
    putOpt(m, 'multi-file-dest', multiFileTarget);
    putOpt(m, 'field-tags', fieldTags);
    putOpt(m, 'omit-empty', omitEmpty);
    return m;
  }
}
