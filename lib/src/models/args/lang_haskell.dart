import '../args.dart';

/// Haskell language specific options for quicktype code generation.
class HaskellArgs {
  HaskellArgs._();

  static Map<String, Arg> get args => {
        justTypes.name: justTypes,
        module.name: module,
        arrayType.name: arrayType,
      };

  static BoolArg get justTypes => BoolArg('just-types');

  static StringArg get module => StringArg('module');

  static EnumArg<ArrayType> get arrayType => EnumArg<ArrayType>('array-type');
}
