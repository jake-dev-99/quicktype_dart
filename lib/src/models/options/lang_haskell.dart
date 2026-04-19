
library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Haskell target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class HaskellRendererOptions extends RendererOptions {
  const HaskellRendererOptions({
    this.justTypes,
    this.module,
    this.arrayType,
  });

  final bool? justTypes;
  final String? module;
  final ArrayType? arrayType;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (module != null) m['module'] = module!;
    if (arrayType != null) m['array-type'] = arrayType!.toString();
    return m;
  }
}
