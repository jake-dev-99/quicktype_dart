// ignore_for_file: public_member_api_docs
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
    putOpt(m, 'density', density);
    putOpt(m, 'visibility', visibility);
    putOpt(m, 'derive-debug', deriveDebug);
    putOpt(m, 'derive-clone', deriveClone);
    putOpt(m, 'derive-partial-eq', derivePartialEq);
    putOpt(m, 'edition-2018', edition2018);
    putOpt(m, 'leading-comments', leadingComments);
    putOpt(m, 'skip-serializing-none', skipSerializingNone);
    return m;
  }
}
