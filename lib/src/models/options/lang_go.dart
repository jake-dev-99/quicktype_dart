
library;

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
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (justTypesAndPackage != null) m['just-types-and-package'] = justTypesAndPackage.toString();
    if (package != null) m['package'] = package!;
    if (multiFileTarget != null) m['multi-file-dest'] = multiFileTarget.toString();
    if (fieldTags != null) m['field-tags'] = fieldTags!;
    if (omitEmpty != null) m['omit-empty'] = omitEmpty.toString();
    return m;
  }
}
