
library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Scala3 target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class Scala3RendererOptions extends RendererOptions {
  const Scala3RendererOptions({
    this.framework,
    this.package,
  });

  final Scala3Framework? framework;
  final String? package;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (framework != null) m['framework'] = framework!.toString();
    if (package != null) m['package'] = package!;
    return m;
  }
}
