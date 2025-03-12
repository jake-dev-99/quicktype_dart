import '../args.dart';

/// Scala 3 Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for Scala 3-specific features of quicktype.
class Scala3Args {
  /// Private constructor to prevent instantiation
  Scala3Args._();

  /// Returns a list of all available Scala 3-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return List of argument builders
  static Map<String, Arg> get args => {
        framework.name: framework,
        package.name: package,
      };

  /// Sets the serialization framework for generated code
  ///
  /// Controls which JSON serialization library is used in the
  /// generated Scala 3 code.
  ///
  /// @return Formatted argument
  static EnumArg<Scala3Framework> get framework =>
      EnumArg<Scala3Framework>('framework');

  /// Sets the package name for generated code
  ///
  /// Defines the package/namespace for the generated Scala 3 types.
  ///
  /// @return Formatted argument
  static StringArg get package => StringArg('package');
}
