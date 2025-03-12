import '../args.dart';

/// PHP Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for PHP-specific features of quicktype.
class PHPArgs {
  /// Private constructor to prevent instantiation
  PHPArgs._();

  /// Returns a list of all available PHP-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return List of argument builders
  static Map<String, Arg> get args => {
        withGet.name: withGet,
        fastGet.name: fastGet,
        withSet.name: withSet,
        withClosing.name: withClosing,
        acronymStyle.name: acronymStyle,
      };

  /// Controls generation of getter methods
  ///
  /// When enabled (default), generates getter methods for all properties.
  ///
  /// @return Formatted argument
  static BoolArg get withGet => BoolArg('with-get');

  /// Controls validation in getter methods
  ///
  /// When enabled, getter methods don't perform type validation,
  /// which improves performance but reduces type safety.
  ///
  /// @return Formatted argument
  static BoolArg get fastGet => BoolArg('fast-get');

  /// Controls generation of setter methods
  ///
  /// When enabled, generates setter methods for all properties.
  ///
  /// @return Formatted argument
  static BoolArg get withSet => BoolArg('with-set');

  /// Controls PHP closing tags
  ///
  /// When enabled, adds the PHP closing tag (?>) at the end of files.
  /// Modern PHP standards recommend omitting this tag.
  ///
  /// @return Formatted argument
  static BoolArg get withClosing => BoolArg('with-closing');

  /// Sets the capitalization style for acronyms
  ///
  /// Controls how acronyms like "URL" or "JSON" are capitalized
  /// in property and method names.
  ///
  /// @return Formatted argument
  static EnumArg<AcronymStyle> get acronymStyle =>
      EnumArg<AcronymStyle>('acronym-style');
}
