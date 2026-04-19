library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Swift target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
class SwiftRendererOptions extends RendererOptions {
  const SwiftRendererOptions({
    this.justTypes,
    this.structOrClass,
    this.density,
    this.initializers,
    this.codingKeys,
    this.codingKeysProtocol,
    this.accessLevel,
    this.alamofire,
    this.supportLinux,
    this.typePrefix,
    this.protocol,
    this.acronymStyle,
    this.objectiveCSupport,
    this.optionalEnums,
    this.sendable,
    this.swift5Support,
    this.multiFileTarget,
    this.mutableProperties,
  });

  /// Maps to the `--just-types` flag.
  final bool? justTypes;
  /// Maps to the `--struct-or-class` flag.
  final StructOrClass? structOrClass;
  /// Maps to the `--density` flag.
  final Density? density;
  /// Maps to the `--initializers` flag.
  final bool? initializers;
  /// Maps to the `--coding-keys` flag.
  final bool? codingKeys;
  /// Maps to the `--coding-keys-protocol` flag.
  final String? codingKeysProtocol;
  /// Maps to the `--access-level` flag.
  final SwiftAccessLevel? accessLevel;
  /// Maps to the `--alamofire` flag.
  final bool? alamofire;
  /// Maps to the `--support-linux` flag.
  final bool? supportLinux;
  /// Maps to the `--type-prefix` flag.
  final String? typePrefix;
  /// Maps to the `--protocol` flag.
  final SwiftProtocol? protocol;
  /// Maps to the `--acronym-style` flag.
  final AcronymStyle? acronymStyle;
  /// Maps to the `--objective-c-support` flag.
  final bool? objectiveCSupport;
  /// Maps to the `--optional-enums` flag.
  final bool? optionalEnums;
  /// Maps to the `--sendable` flag.
  final bool? sendable;
  /// Maps to the `--swift-5-support` flag.
  final bool? swift5Support;
  /// Maps to the `--multi-file-dest` flag.
  final bool? multiFileTarget;
  /// Maps to the `--mutable-properties` flag.
  final bool? mutableProperties;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (structOrClass != null) m['struct-or-class'] = structOrClass!.toString();
    if (density != null) m['density'] = density!.toString();
    if (initializers != null) m['initializers'] = initializers.toString();
    if (codingKeys != null) m['coding-keys'] = codingKeys.toString();
    if (codingKeysProtocol != null) m['coding-keys-protocol'] = codingKeysProtocol!;
    if (accessLevel != null) m['access-level'] = accessLevel!.toString();
    if (alamofire != null) m['alamofire'] = alamofire.toString();
    if (supportLinux != null) m['support-linux'] = supportLinux.toString();
    if (typePrefix != null) m['type-prefix'] = typePrefix!;
    if (protocol != null) m['protocol'] = protocol!.toString();
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (objectiveCSupport != null) m['objective-c-support'] = objectiveCSupport.toString();
    if (optionalEnums != null) m['optional-enums'] = optionalEnums.toString();
    if (sendable != null) m['sendable'] = sendable.toString();
    if (swift5Support != null) m['swift-5-support'] = swift5Support.toString();
    if (multiFileTarget != null) m['multi-file-dest'] = multiFileTarget.toString();
    if (mutableProperties != null) m['mutable-properties'] = mutableProperties.toString();
    return m;
  }
}
