import '../args.dart';

/// Ruby language specific options for quicktype code generation.
@Deprecated('Use RubyRendererOptions instead — removal planned for v0.4.0')
class RubyArgs {
  RubyArgs._();

  static Map<String, Arg> get args => {
        justTypes.name: justTypes,
        strictness.name: strictness,
        namespace.name: namespace,
      };

  static BoolArg get justTypes => BoolArg('just-types');

  static EnumArg<RubyStrictness> get strictness =>
      EnumArg<RubyStrictness>('strictness');

  static StringArg get namespace => StringArg('namespace');
}
