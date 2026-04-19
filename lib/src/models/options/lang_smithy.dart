
library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Smithy target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class SmithyRendererOptions extends RendererOptions {
  const SmithyRendererOptions({
    this.framework,
    this.package,
  });

  final SmithyFramework? framework;
  final String? package;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (framework != null) m['framework'] = framework!.toString();
    if (package != null) m['package'] = package!;
    return m;
  }
}
