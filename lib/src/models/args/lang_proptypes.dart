import '../args.dart';

/// JavaScript PropTypes specific options for quicktype code generation.
class PropTypesArgs {
  PropTypesArgs._();

  static Map<String, Arg> get args => {
        acronymStyle.name: acronymStyle,
        converters.name: converters,
      };

  static EnumArg<AcronymStyle> get acronymStyle =>
      EnumArg<AcronymStyle>('acronym-style');

  static EnumArg<ConverterType> get converters =>
      EnumArg<ConverterType>('converters');
}
