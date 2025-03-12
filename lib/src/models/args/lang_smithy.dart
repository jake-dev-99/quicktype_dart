import '../args.dart';

/// Smithy Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for Smithy-specific features of quicktype.
class SmithyArgs {
  /// Private constructor to prevent instantiation
  SmithyArgs._();

  /// Returns a list of all available Smithy-specific arguments
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
  /// Controls which serialization approach is used in the
  /// generated Smithy code.
  ///
  /// @return Formatted argument
  static EnumArg<SmithyFramework> get framework =>
      EnumArg<SmithyFramework>('framework');

  /// Sets the package name for generated code
  ///
  /// Defines the package/namespace for the generated Smithy types.
  ///
  /// @return Formatted argument
  static StringArg get package => StringArg('package');
}
