import '../args.dart';

/// Java Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for Java-specific features of quicktype.
@Deprecated('Use JavaRendererOptions instead — removal planned for v0.4.0')
class JavaArgs {
  /// Private constructor to prevent instantiation
  JavaArgs._();

  /// Returns a list of all available Java-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return List of argument builders
  static Map<String, Arg> get args => {
        arrayType.name: arrayType,
        justTypes.name: justTypes,
        datetimeProvider.name: datetimeProvider,
        acronymStyle.name: acronymStyle,
        package.name: package,
        lombok.name: lombok,
        lombokCopyAnnotations.name: lombokCopyAnnotations,
      };

  /// Sets the collection type to use for arrays
  ///
  /// Controls whether JSON arrays are represented as Java arrays (T[])
  /// or Java Lists (List<T>).
  ///
  /// @return Formatted argument
  static EnumArg<ArrayType> get arrayType => EnumArg<ArrayType>('array-type');

  /// Controls generation of type definitions only
  ///
  /// When enabled, generates only Java class definitions without
  /// serialization/deserialization code.
  ///
  /// @return Formatted argument
  static BoolArg get justTypes => BoolArg('just-types');

  /// Sets the date/time handling implementation
  ///
  /// Controls whether modern Java 8 time classes or legacy
  /// Date classes are used for date/time values.
  ///
  /// @return Formatted argument
  static EnumArg<DateTimeProvider> get datetimeProvider =>
      EnumArg<DateTimeProvider>('datetime-provider');

  /// Sets the capitalization style for acronyms
  ///
  /// Controls how acronyms like "URL" or "JSON" are capitalized
  /// in property and method names.
  ///
  /// @return Formatted argument
  static EnumArg<AcronymStyle> get acronymStyle =>
      EnumArg<AcronymStyle>('acronym-style');

  /// Sets the package name for generated code
  ///
  /// Specifies the Java package declaration for all generated classes.
  ///
  /// @return Formatted argument
  static StringArg get package => StringArg('package');

  /// Controls generation of Lombok annotations
  ///
  /// When enabled, generates Lombok annotations (@Data, etc.)
  /// instead of explicit getters/setters.
  ///
  /// @return Formatted argument
  static BoolArg get lombok => BoolArg('lombok');

  /// Controls copying of accessor annotations
  ///
  /// When enabled (default) and lombok is enabled, copies annotations
  /// from fields to generated accessors.
  ///
  /// @return Formatted argument
  static BoolArg get lombokCopyAnnotations =>
      BoolArg('lombok-copy-annotations');
}
