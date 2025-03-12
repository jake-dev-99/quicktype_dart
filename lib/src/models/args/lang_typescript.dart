import '../args.dart';

/// TypeScript Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for TypeScript-specific features of quicktype.
class TypeScriptArgs {
  /// Private constructor to prevent instantiation
  TypeScriptArgs._();

  /// Controls generation of type definitions only
  ///
  /// When enabled, generates only TypeScript interface definitions without
  /// serialization/deserialization code.
  ///
  /// @return Formatted argument
  static BoolArg get justTypes => BoolArg('just-types');

  /// Controls property name formatting
  ///
  /// When enabled, property names are transformed to follow JavaScript
  /// naming conventions.
  ///
  /// @return Formatted argument
  static BoolArg get nicePropertyNames => BoolArg('nice-property-names');

  /// Controls union type naming
  ///
  /// When enabled, union types are given explicit names rather than
  /// being defined inline.
  ///
  /// @return Formatted argument
  static BoolArg get explicitUnions => BoolArg('explicit-unions');

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

  /// Controls union vs enum preference
  ///
  /// When enabled, union types are used instead of enums where applicable.
  ///
  /// @return Formatted argument
  static BoolArg get preferUnions => BoolArg('prefer-unions');

  /// Controls type vs interface preference
  ///
  /// When enabled, 'type' definitions are used instead of 'interface' definitions.
  ///
  /// @return Formatted argument
  static BoolArg get preferTypes => BoolArg('prefer-types');

  /// Controls single-value string enum representation
  ///
  /// When enabled, string enums with a single value use string literals
  /// instead of enum types.
  ///
  /// @return Formatted argument
  static BoolArg get preferConstValues => BoolArg('prefer-const-values');

  /// Controls type member mutability
  ///
  /// When enabled, type members are marked as readonly.
  ///
  /// @return Formatted argument
  static BoolArg get readonly => BoolArg('readonly');

  /// Returns a map of all available TypeScript-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return Map of argument names to argument builders
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
}
