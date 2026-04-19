library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Kotlin target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class KotlinRendererOptions extends RendererOptions {
  const KotlinRendererOptions({
    this.framework,
    this.acronymStyle,
    this.package,
  });

  /// Maps to the `--framework` flag.
  final KotlinFramework? framework;
  /// Maps to the `--acronym-style` flag.
  final AcronymStyle? acronymStyle;
  /// Maps to the `--package` flag.
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
