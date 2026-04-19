library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Rust target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
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

  /// Maps to the `--density` flag.
  final Density? density;
  /// Maps to the `--visibility` flag.
  final RustVisibility? visibility;
  /// Maps to the `--derive-debug` flag.
  final bool? deriveDebug;
  /// Maps to the `--derive-clone` flag.
  final bool? deriveClone;
  /// Maps to the `--derive-partial-eq` flag.
  final bool? derivePartialEq;
  /// Maps to the `--edition-2018` flag.
  final bool? edition2018;
  /// Maps to the `--leading-comments` flag.
  final bool? leadingComments;
  /// Maps to the `--skip-serializing-none` flag.
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
