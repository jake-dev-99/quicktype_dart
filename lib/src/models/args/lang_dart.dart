import '../args.dart';

/// Dart Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for Dart-specific features of quicktype.
class DartArgs {
  /// Private constructor to prevent instantiation
  DartArgs._();

  /// Returns a list of all available Dart-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return List of argument builders
  static Map<String, Arg> get args => {
        nullSafety.name: nullSafety,
        justTypes.name: justTypes,
        codersInClass.name: codersInClass,
        fromMap.name: fromMap,
        requiredProps.name: requiredProps,
        finalProps.name: finalProps,
        copyWith.name: copyWith,
        useFreezed.name: useFreezed,
        useHive.name: useHive,
        useJsonAnnotation.name: useJsonAnnotation,
        partName.name: partName,
      };

  /// Controls null safety support
  ///
  /// When enabled, generated Dart code will use null safety features.
  /// Enabled by default.
  ///
  /// @return Formatted argument
  static BoolArg get nullSafety => BoolArg('null-safety');

  /// Controls generation of type definitions only
  ///
  /// When enabled, generates only Dart class definitions without
  /// serialization/deserialization code.
  ///
  /// @return Formatted argument
  static BoolArg get justTypes => BoolArg('just-types');

  /// Controls location of encoder/decoder methods
  ///
  /// When enabled, JSON encoder and decoder methods are placed
  /// inside the class rather than as extensions.
  ///
  /// @return Formatted argument
  static BoolArg get codersInClass => BoolArg('coders-in-class');

  /// Controls method naming convention
  ///
  /// When enabled, uses fromMap() and toMap() method names
  /// instead of fromJson() and toJson().
  ///
  /// @return Formatted argument
  static BoolArg get fromMap => BoolArg('from-map');

  /// Controls property requirement
  ///
  /// When enabled, all properties in generated classes will be
  /// marked as required.
  ///
  /// @return Formatted argument
  static BoolArg get requiredProps => BoolArg('required-props');

  /// Controls property mutability
  ///
  /// When enabled, all properties in generated classes will be
  /// marked as final.
  ///
  /// @return Formatted argument
  static BoolArg get finalProps => BoolArg('final-props');

  /// Controls generation of copyWith method
  ///
  /// When enabled, a copyWith method will be generated for
  /// all classes to support immutable updates.
  ///
  /// @return Formatted argument
  static BoolArg get copyWith => BoolArg('copy-with');

  /// Controls freezed package compatibility
  ///
  /// When enabled, generates class definitions compatible
  /// with the freezed package annotations.
  ///
  /// @return Formatted argument
  static BoolArg get useFreezed => BoolArg('use-freezed');

  /// Controls Hive compatibility
  ///
  /// When enabled, generates annotations for Hive type adapters.
  ///
  /// @return Formatted argument
  static BoolArg get useHive => BoolArg('use-hive');

  /// Controls json_serializable compatibility
  ///
  /// When enabled, generates annotations for the json_serializable package.
  ///
  /// @return Formatted argument
  static BoolArg get useJsonAnnotation => BoolArg('use-json-annotation');

  /// Sets the name to use in part directive
  ///
  /// Specifies the file name to be used in the 'part' directive
  /// for generated Dart code.
  ///
  /// @return Formatted argument
  static StringArg get partName => StringArg('part-name');
}
