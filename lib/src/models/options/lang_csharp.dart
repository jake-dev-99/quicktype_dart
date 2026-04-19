library;

import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the CSharp target.
///
/// Pass to [QuicktypeDart.generate] via `options:`.
///
/// See quicktype-core's documentation for the authoritative list of
/// flags per language.
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

  /// Maps to the `--framework` flag.
  final CSharpFramework? framework;
  /// Maps to the `--namespace` flag.
  final String? namespace;
  /// Maps to the `--csharp-version` flag.
  final CSharpVersion? csharpVersion;
  /// Maps to the `--density` flag.
  final Density? density;
  /// Maps to the `--array-type` flag.
  final ArrayType? arrayType;
  /// Maps to the `--number-type` flag.
  final NumberType? numberType;
  /// Maps to the `--any-type` flag.
  final AnyType? anyType;
  /// Maps to the `--virtual` flag.
  final bool? virtual;
  /// Maps to the `--features` flag.
  final Features? features;
  /// Maps to the `--base-class` flag.
  final BaseClass? baseClass;
  /// Maps to the `--check-required` flag.
  final bool? checkRequired;
  /// Maps to the `--keep-property-name` flag.
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
    if (keepPropertyName != null) m['keep-property-name'] = keepPropertyName.toString();
    return m;
  }
}
