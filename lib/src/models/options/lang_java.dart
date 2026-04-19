// ignore_for_file: public_member_api_docs
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Java target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
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

  final ArrayType? arrayType;
  final bool? justTypes;
  final DateTimeProvider? datetimeProvider;
  final AcronymStyle? acronymStyle;
  final String? package;
  final bool? lombok;
  final bool? lombokCopyAnnotations;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (arrayType != null) m['array-type'] = arrayType!.toString();
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (datetimeProvider != null) {
      m['datetime-provider'] = datetimeProvider!.toString();
    }
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (package != null) m['package'] = package!;
    if (lombok != null) m['lombok'] = lombok.toString();
    if (lombokCopyAnnotations != null) {
      m['lombok-copy-annotations'] = lombokCopyAnnotations.toString();
    }
    return m;
  }
}
