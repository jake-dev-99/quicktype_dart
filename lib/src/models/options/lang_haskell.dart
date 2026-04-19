library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Haskell target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class HaskellRendererOptions extends RendererOptions {
  const HaskellRendererOptions({
    this.justTypes,
    this.module,
    this.arrayType,
  });

  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--module` flag.
  final String? module;
  /// Maps to the `--array-type` flag.
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
