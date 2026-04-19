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
    if (framework != null) m['framework'] = framework!.toString();
    if (namespace != null) m['namespace'] = namespace!;
    if (csharpVersion != null) m['csharp-version'] = csharpVersion!.toString();
    if (density != null) m['density'] = density!.toString();
    if (arrayType != null) m['array-type'] = arrayType!.toString();
    if (numberType != null) m['number-type'] = numberType!.toString();
    if (anyType != null) m['any-type'] = anyType!.toString();
    if (virtual != null) m['virtual'] = virtual.toString();
    if (features != null) m['features'] = features!.toString();
    if (baseClass != null) m['base-class'] = baseClass!.toString();
    if (checkRequired != null) m['check-required'] = checkRequired.toString();
    if (keepPropertyName != null) {
      m['keep-property-name'] = keepPropertyName.toString();
    }
    return m;
  }
}
