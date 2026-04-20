// ignore_for_file: public_member_api_docs
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
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'struct-or-class', structOrClass);
    putOpt(m, 'density', density);
    putOpt(m, 'initializers', initializers);
    putOpt(m, 'coding-keys', codingKeys);
    putOpt(m, 'coding-keys-protocol', codingKeysProtocol);
    putOpt(m, 'access-level', accessLevel);
    putOpt(m, 'alamofire', alamofire);
    putOpt(m, 'support-linux', supportLinux);
    putOpt(m, 'type-prefix', typePrefix);
    putOpt(m, 'protocol', protocol);
    putOpt(m, 'acronym-style', acronymStyle);
    putOpt(m, 'objective-c-support', objectiveCSupport);
    putOpt(m, 'optional-enums', optionalEnums);
    putOpt(m, 'sendable', sendable);
    putOpt(m, 'swift-5-support', swift5Support);
    putOpt(m, 'multi-file-dest', multiFileTarget);
    putOpt(m, 'mutable-properties', mutableProperties);
    return m;
  }
}
