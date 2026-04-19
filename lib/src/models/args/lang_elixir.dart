import '../args.dart';

/// Elixir language specific options for quicktype code generation.
class ElixirArgs {
  ElixirArgs._();

  static Map<String, Arg> get args => {
        justTypes.name: justTypes,
        namespace.name: namespace,
      };

  static BoolArg get justTypes => BoolArg('just-types');

  static StringArg get namespace => StringArg('namespace');
}
