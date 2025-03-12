import '../args.dart';

/// JavaScript Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for JavaScript-specific features of quicktype.
class JavaScriptArgs {
  /// Private constructor to prevent instantiation
  JavaScriptArgs._();

  /// Returns a map of all available JavaScript-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return Map of argument names to argument builders
  static Map<String, Arg> get args => {
        copyAccessorAnnotations.name: copyAccessorAnnotations,
        runtimeTypecheck.name: runtimeTypecheck,
        runtimeTypecheckIgnoreUnknownProperties.name:
            runtimeTypecheckIgnoreUnknownProperties,
        acronymStyle.name: acronymStyle,
        converters.name: converters,
        rawType.name: rawType,
      };

  /// Controls copying of accessor annotations
  ///
  /// When enabled, accessor annotations from the input are copied to
  /// the generated code.
  ///
  /// @return Formatted argument
  static BoolArg get copyAccessorAnnotations =>
      BoolArg('copy-accessor-annotations');

  /// Controls runtime type checking
  ///
  /// When enabled, generates code to verify results from JSON.parse
  /// at runtime.
  ///
  /// @return Formatted argument
  static BoolArg get runtimeTypecheck => BoolArg('runtime-typecheck');

  /// Controls unknown property handling during runtime checks
  ///
  /// When enabled, unknown properties are ignored during runtime
  /// type verification.
  ///
  /// @return Formatted argument
  static BoolArg get runtimeTypecheckIgnoreUnknownProperties =>
      BoolArg('runtime-typecheck-ignore-unknown-properties');

  /// Sets the acronym naming style
  ///
  /// Controls how acronyms in property and type names are formatted.
  ///
  /// @return Formatted argument
  static EnumArg<AcronymStyle> get acronymStyle =>
      EnumArg<AcronymStyle>('acronym-style');

  /// Sets the converter generation scope
  ///
  /// Controls which types get converter functions generated.
  ///
  /// @return Formatted argument
  static EnumArg<ConverterType> get converters =>
      EnumArg<ConverterType>('converters');

  /// Sets the raw input type
  ///
  /// Controls the type used for raw JSON input.
  ///
  /// @return Formatted argument
  static EnumArg<RawType> get rawType => EnumArg<RawType>('raw-type');
}
