
import '../enums.dart';
import '../renderer_options.dart';

/// Named-parameter options for the Python target.
///
/// Pass to [QuicktypeDart.generate] via `options:`. See quicktype-core's docs for the authoritative list of flags.
class PythonRendererOptions extends RendererOptions {
  const PythonRendererOptions({
    this.pythonVersion,
    this.justTypes,
    this.nicePropertyNames,
    this.pydanticBaseModel,
  });

  final PythonVersion? pythonVersion;
  final bool? justTypes;
  final bool? nicePropertyNames;
  final bool? pydanticBaseModel;

  @override
  Map<String, String> toRendererOptions() {
    final m = <String, String>{};
    if (pythonVersion != null) m['python-version'] = pythonVersion!.toString();
    if (justTypes != null) m['just-types'] = justTypes.toString();
    if (nicePropertyNames != null) m['nice-property-names'] = nicePropertyNames.toString();
    if (pydanticBaseModel != null) m['pydantic-base-model'] = pydanticBaseModel.toString();
    return m;
  }
}
