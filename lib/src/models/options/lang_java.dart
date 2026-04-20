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
    putOpt(m, 'array-type', arrayType);
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'datetime-provider', datetimeProvider);
    putOpt(m, 'acronym-style', acronymStyle);
    putOpt(m, 'package', package);
    putOpt(m, 'lombok', lombok);
    putOpt(m, 'lombok-copy-annotations', lombokCopyAnnotations);
    return m;
  }
}
