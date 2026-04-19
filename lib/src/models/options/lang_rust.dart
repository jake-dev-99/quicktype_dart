
library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Rust target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class RustRendererOptions extends RendererOptions {
  const RustRendererOptions({
    this.density,
    this.visibility,
    this.deriveDebug,
    this.deriveClone,
    this.derivePartialEq,
    this.edition2018,
    this.leadingComments,
    this.skipSerializingNone,
  });

  final Density? density;
  final RustVisibility? visibility;
  final bool? deriveDebug;
  final bool? deriveClone;
  final bool? derivePartialEq;
  final bool? edition2018;
  final bool? leadingComments;
  final bool? skipSerializingNone;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (density != null) m['density'] = density!.toString();
    if (visibility != null) m['visibility'] = visibility!.toString();
    if (deriveDebug != null) m['derive-debug'] = deriveDebug.toString();
    if (deriveClone != null) m['derive-clone'] = deriveClone.toString();
    if (derivePartialEq != null) m['derive-partial-eq'] = derivePartialEq.toString();
    if (edition2018 != null) m['edition-2018'] = edition2018.toString();
    if (leadingComments != null) m['leading-comments'] = leadingComments.toString();
    if (skipSerializingNone != null) m['skip-serializing-none'] = skipSerializingNone.toString();
    return m;
  }
}
