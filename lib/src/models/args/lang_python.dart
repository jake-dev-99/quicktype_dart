import '../args.dart';

/// Python language specific options for quicktype code generation.
@Deprecated('Use PythonRendererOptions instead — removal planned for v0.4.0')
class PythonArgs {
  PythonArgs._();

  static Map<String, Arg> get args => {
        pythonVersion.name: pythonVersion,
        justTypes.name: justTypes,
        nicePropertyNames.name: nicePropertyNames,
        pydanticBaseModel.name: pydanticBaseModel,
      };

  static EnumArg<PythonVersion> get pythonVersion =>
      EnumArg<PythonVersion>('python-version');

  static BoolArg get justTypes => BoolArg('just-types');
  static BoolArg get nicePropertyNames => BoolArg('nice-property-names');
  static BoolArg get pydanticBaseModel => BoolArg('pydantic-base-model');
}
