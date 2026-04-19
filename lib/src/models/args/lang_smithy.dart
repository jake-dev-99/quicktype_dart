import '../args.dart';

/// Smithy language specific options for quicktype code generation.
@Deprecated('Use SmithyRendererOptions instead — removal planned for v0.4.0')
class SmithyArgs {
  SmithyArgs._();

  static Map<String, Arg> get args => {
        framework.name: framework,
        package.name: package,
      };

  static EnumArg<SmithyFramework> get framework =>
      EnumArg<SmithyFramework>('framework');

  static StringArg get package => StringArg('package');
}
