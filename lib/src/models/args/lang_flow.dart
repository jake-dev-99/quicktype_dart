import '../args.dart';

/// Flow language specific options for quicktype code generation.
class FlowArgs {
  FlowArgs._();

  static Map<String, Arg> get args => {
        justTypes.name: justTypes,
        nicePropertyNames.name: nicePropertyNames,
        explicitUnions.name: explicitUnions,
        runtimeTypecheck.name: runtimeTypecheck,
        runtimeTypecheckIgnoreUnknownProperties.name:
            runtimeTypecheckIgnoreUnknownProperties,
        acronymStyle.name: acronymStyle,
        converters.name: converters,
        rawType.name: rawType,
        preferUnions.name: preferUnions,
        preferTypes.name: preferTypes,
        preferConstValues.name: preferConstValues,
        readonly.name: readonly,
      };

  static BoolArg get justTypes => BoolArg('just-types');
  static BoolArg get nicePropertyNames => BoolArg('nice-property-names');
  static BoolArg get explicitUnions => BoolArg('explicit-unions');
  static BoolArg get runtimeTypecheck => BoolArg('runtime-typecheck');
  static BoolArg get runtimeTypecheckIgnoreUnknownProperties =>
      BoolArg('runtime-typecheck-ignore-unknown-properties');

  static EnumArg<AcronymStyle> get acronymStyle =>
      EnumArg<AcronymStyle>('acronym-style');

  static EnumArg<ConverterType> get converters =>
      EnumArg<ConverterType>('converters');

  static EnumArg<RawType> get rawType => EnumArg<RawType>('raw-type');

  static BoolArg get preferUnions => BoolArg('prefer-unions');
  static BoolArg get preferTypes => BoolArg('prefer-types');
  static BoolArg get preferConstValues => BoolArg('prefer-const-values');
  static BoolArg get readonly => BoolArg('readonly');
}
