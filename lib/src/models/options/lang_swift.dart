import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Swift target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
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

  final bool? justTypes;
  final StructOrClass? structOrClass;
  final Density? density;
  final bool? initializers;
  final bool? codingKeys;
  final String? codingKeysProtocol;
  final SwiftAccessLevel? accessLevel;
  final bool? alamofire;
  final bool? supportLinux;
  final String? typePrefix;
  final SwiftProtocol? protocol;
  final AcronymStyle? acronymStyle;
  final bool? objectiveCSupport;
  final bool? optionalEnums;
  final bool? sendable;
  final bool? swift5Support;
  final bool? multiFileTarget;
  final bool? mutableProperties;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (structOrClass != null) m['struct-or-class'] = structOrClass!.toString();
    if (density != null) m['density'] = density!.toString();
    if (initializers != null) m['initializers'] = initializers.toString();
    if (codingKeys != null) m['coding-keys'] = codingKeys.toString();
    if (codingKeysProtocol != null) {
      m['coding-keys-protocol'] = codingKeysProtocol!;
    }
    if (accessLevel != null) m['access-level'] = accessLevel!.toString();
    if (alamofire != null) m['alamofire'] = alamofire.toString();
    if (supportLinux != null) m['support-linux'] = supportLinux.toString();
    if (typePrefix != null) m['type-prefix'] = typePrefix!;
    if (protocol != null) m['protocol'] = protocol!.toString();
    if (acronymStyle != null) m['acronym-style'] = acronymStyle!.toString();
    if (objectiveCSupport != null) {
      m['objective-c-support'] = objectiveCSupport.toString();
    }
    if (optionalEnums != null) m['optional-enums'] = optionalEnums.toString();
    if (sendable != null) m['sendable'] = sendable.toString();
    if (swift5Support != null) m['swift-5-support'] = swift5Support.toString();
    if (multiFileTarget != null) {
      m['multi-file-dest'] = multiFileTarget.toString();
    }
    if (mutableProperties != null) {
      m['mutable-properties'] = mutableProperties.toString();
    }
    return m;
  }
}
