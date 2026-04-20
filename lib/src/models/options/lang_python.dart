// ignore_for_file: public_member_api_docs
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
    putOpt(m, 'python-version', pythonVersion);
    putOpt(m, 'just-types', justTypes);
    putOpt(m, 'nice-property-names', nicePropertyNames);
    putOpt(m, 'pydantic-base-model', pydanticBaseModel);
    return m;
  }
}
