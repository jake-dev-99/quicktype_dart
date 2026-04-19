library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Java target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class JavaRendererOptions extends RendererOptions {
  const JavaRendererOptions({
    this.arrayType,
    this.justTypes,
    this.datetimeProvider,
    this.acronymStyle,
    this.package,
    this.lombok,
    this.lombokCopyAnnotations,
  });

  /// Maps to the `--array-type` flag.
  final ArrayType? arrayType;
  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--datetime-provider` flag.
  final DateTimeProvider? datetimeProvider;
  /// Maps to the `--acronym-style` flag.
  final AcronymStyle? acronymStyle;
  /// Maps to the `--package` flag.
  final String? package;
  /// Maps to the `--lombok` flag.
  final bool? lombok;
  /// Maps to the `--lombok-copy-annotations` flag.
  final bool? lombokCopyAnnotations;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (arrayType != null) m['array-type'] = arrayType!.toString();
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (datetimeProvider != null) m['datetime-provider'] = datetimeProvider!.toString();
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (package != null) m['package'] = package!;
    if (lombok != null) m['lombok'] = lombok.toString();
    if (lombokCopyAnnotations != null) m['lombok-copy-annotations'] = lombokCopyAnnotations.toString();
    return m;
  }
}
