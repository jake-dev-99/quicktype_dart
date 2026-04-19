import '../args.dart';

/// C# language specific options for quicktype code generation.
@Deprecated('Use CSharpRendererOptions instead — removal planned for v0.4.0')
class CSharpArgs {
  CSharpArgs._();

  static Map<String, Arg> get args => {
        framework.name: framework,
        namespace.name: namespace,
        csharpVersion.name: csharpVersion,
        density.name: density,
        arrayType.name: arrayType,
        numberType.name: numberType,
        anyType.name: anyType,
        virtual.name: virtual,
        features.name: features,
        baseClass.name: baseClass,
        checkRequired.name: checkRequired,
        keepPropertyName.name: keepPropertyName,
      };

  static EnumArg<CSharpFramework> get framework =>
      EnumArg<CSharpFramework>('framework');

  static StringArg get namespace => StringArg('namespace');

  static EnumArg<CSharpVersion> get csharpVersion =>
      EnumArg<CSharpVersion>('csharp-version');

  static EnumArg<Density> get density => EnumArg<Density>('density');

  static EnumArg<ArrayType> get arrayType => EnumArg<ArrayType>('array-type');

  static EnumArg<NumberType> get numberType =>
      EnumArg<NumberType>('number-type');

  static EnumArg<AnyType> get anyType => EnumArg<AnyType>('any-type');

  static BoolArg get virtual => BoolArg('virtual');

  static EnumArg<Features> get features => EnumArg<Features>('features');

  static EnumArg<BaseClass> get baseClass => EnumArg<BaseClass>('base-class');

  static BoolArg get checkRequired => BoolArg('check-required');

  static BoolArg get keepPropertyName => BoolArg('keep-property-name');
}
