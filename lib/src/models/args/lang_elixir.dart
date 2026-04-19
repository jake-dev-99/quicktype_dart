import '../args.dart';

/// Elixir language specific options for quicktype code generation.
@Deprecated('Use ElixirRendererOptions instead — removal planned for v0.4.0')
class ElixirArgs {
  ElixirArgs._();

  static Map<String, Arg> get args => {
        justTypes.name: justTypes,
        namespace.name: namespace,
      };

  static BoolArg get justTypes => BoolArg('just-types');

  static StringArg get namespace => StringArg('namespace');
}
