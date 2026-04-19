
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Kotlin target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class KotlinRendererOptions extends RendererOptions {
  const KotlinRendererOptions({
    this.framework,
    this.acronymStyle,
    this.package,
  });

  final KotlinFramework? framework;
  final AcronymStyle? acronymStyle;
  final String? package;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (framework != null) m['framework'] = framework!.toString();
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (package != null) m['package'] = package!;
    return m;
  }
}
