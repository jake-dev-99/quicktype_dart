import '../args.dart';

/// Kotlin Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for Kotlin-specific features of quicktype.
class KotlinArgs {
  /// Private constructor to prevent instantiation
  KotlinArgs._();

  /// Returns a list of all available Kotlin-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return List of argument builders
  static Map<String, Arg> get args => {
        framework.name: framework,
        acronymStyle.name: acronymStyle,
        package.name: package,
      };

  /// Sets the serialization framework for generated code
  ///
  /// Controls which JSON serialization library is used in the
  /// generated Kotlin code.
  ///
  /// @return Formatted argument
  static EnumArg<KotlinFramework> get framework =>
      EnumArg<KotlinFramework>('framework');

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
  /// Defines the package/namespace for the generated Kotlin types.
  ///
  /// @return Formatted argument
  static StringArg get package => StringArg('package');
}
