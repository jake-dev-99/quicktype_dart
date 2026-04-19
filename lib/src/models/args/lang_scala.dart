import '../args.dart';

/// Scala 3 language specific options for quicktype code generation.
@Deprecated('Use Scala3RendererOptions instead — removal planned for v0.4.0')
class Scala3Args {
  Scala3Args._();

  static Map<String, Arg> get args => {
        framework.name: framework,
        package.name: package,
      };

  static EnumArg<Scala3Framework> get framework =>
      EnumArg<Scala3Framework>('framework');

  static StringArg get package => StringArg('package');
}
