library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Smithy target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class SmithyRendererOptions extends RendererOptions {
  const SmithyRendererOptions({
    this.framework,
    this.package,
  });

  /// Maps to the `--framework` flag.
  final SmithyFramework? framework;
  /// Maps to the `--package` flag.
  final String? package;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (framework != null) m['framework'] = framework!.toString();
    if (package != null) m['package'] = package!;
    return m;
  }
}
