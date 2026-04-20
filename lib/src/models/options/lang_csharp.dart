// ignore_for_file: public_member_api_docs
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the CSharp target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class CSharpRendererOptions extends RendererOptions {
  const CSharpRendererOptions({
    this.framework,
    this.namespace,
    this.csharpVersion,
    this.density,
    this.arrayType,
    this.numberType,
    this.anyType,
    this.virtual,
    this.features,
    this.baseClass,
    this.checkRequired,
    this.keepPropertyName,
  });

  final CSharpFramework? framework;
  final String? namespace;
  final CSharpVersion? csharpVersion;
  final Density? density;
  final ArrayType? arrayType;
  final NumberType? numberType;
  final AnyType? anyType;
  final bool? virtual;
  final Features? features;
  final BaseClass? baseClass;
  final bool? checkRequired;
  final bool? keepPropertyName;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    putOpt(m, 'framework', framework);
    putOpt(m, 'namespace', namespace);
    putOpt(m, 'csharp-version', csharpVersion);
    putOpt(m, 'density', density);
    putOpt(m, 'array-type', arrayType);
    putOpt(m, 'number-type', numberType);
    putOpt(m, 'any-type', anyType);
    putOpt(m, 'virtual', virtual);
    putOpt(m, 'features', features);
    putOpt(m, 'base-class', baseClass);
    putOpt(m, 'check-required', checkRequired);
    putOpt(m, 'keep-property-name', keepPropertyName);
    return m;
  }
}
