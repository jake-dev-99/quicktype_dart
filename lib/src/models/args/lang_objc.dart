import '../args.dart';

/// Objective-C Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for Objective-C-specific features of quicktype.
class ObjectiveCArgs {
  /// Private constructor to prevent instantiation
  ObjectiveCArgs._();

  /// Returns a list of all available Objective-C-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return List of argument builders
  static Map<String, Arg> get args => {
        justTypes.name: justTypes,
        classPrefix.name: classPrefix,
        features.name: features,
        extraComments.name: extraComments,
        functions.name: functions,
      };

  /// Controls generation of type definitions only
  ///
  /// When enabled, generates only type definitions without
  /// serialization/deserialization code.
  ///
  /// @return Formatted argument
  static BoolArg get justTypes => BoolArg('just-types');

  /// Sets a prefix for all generated class names
  ///
  /// Following Apple's conventions, adds a prefix to all generated
  /// class names (e.g., "NS" for Apple's Foundation classes).
  ///
  /// @return Formatted argument
  static StringArg get classPrefix => StringArg('class-prefix');

  /// Controls which parts of the code are generated
  ///
  /// Determines whether to generate interface (.h) files,
  /// implementation (.m) files, or both.
  ///
  /// @return Formatted argument
  static EnumArg<ObjectiveCFeatures> get features =>
      EnumArg<ObjectiveCFeatures>('features');

  /// Controls generation of additional comments
  ///
  /// When enabled, generates more verbose documentation comments
  /// in the generated code.
  ///
  /// @return Formatted argument
  static BoolArg get extraComments => BoolArg('extra-comments');

  /// Controls generation of C-style functions
  ///
  /// When enabled, generates C-style functions for serialization
  /// and deserialization in addition to Objective-C methods.
  ///
  /// @return Formatted argument
  static BoolArg get functions => BoolArg('functions');
}
