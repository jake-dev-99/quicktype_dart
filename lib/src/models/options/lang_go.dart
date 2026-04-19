library;

import '../renderer_options.dart';

/// Named-parameter options for the Go target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class GoRendererOptions extends RendererOptions {
  const GoRendererOptions({
    this.justTypes,
    this.justTypesAndPackage,
    this.package,
    this.multiFileTarget,
    this.fieldTags,
    this.omitEmpty,
  });

  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--just-types-and-package` flag.
  final bool? justTypesAndPackage;
  /// Maps to the `--package` flag.
  final String? package;
  /// Maps to the `--multi-file-dest` flag.
  final bool? multiFileTarget;
  /// Maps to the `--field-tags` flag.
  final String? fieldTags;
  /// Maps to the `--omit-empty` flag.
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
