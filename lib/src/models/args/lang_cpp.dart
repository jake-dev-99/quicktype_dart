import '../args.dart';

/// C++ Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for C++-specific features of quicktype.
class CppArgs {
  /// Private constructor to prevent instantiation
  const CppArgs._();

  /// Returns a list of all available C++-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return List of argument builders
  static Map<String, Arg> get args => {
        justTypes.name: justTypes,
        wstring.name: wstring,
        constStyle.name: constStyle,
        enumType.name: enumType,
        namespace.name: namespace,
        codeFormat.name: codeFormat,
        includeStyle.name: includeStyle,
        sourceStyle.name: sourceStyle,
        boost.name: boost,
        hideNullOptional.name: hideNullOptional,
        typeStyle.name: typeStyle,
        memberStyle.name: memberStyle,
        enumeratorStyle.name: enumeratorStyle,
      };

  /// Generates only type definitions without serialization code
  ///
  /// When enabled, quicktype will generate only C++ type declarations
  /// without the code needed to parse JSON into those types.
  ///
  /// @return Formatted argument
  static BoolArg get justTypes => BoolArg('just-types');

  /// Sets the string type to use
  ///
  /// Controls whether the generated code uses std::string or std::wstring
  /// for string values.
  ///
  /// @return Formatted argument
  static EnumArg<WStringType> get wstring => EnumArg<WStringType>('wstring');

  /// Sets the const style for the generated code
  ///
  /// Controls whether const appears to the left (west) or right (east)
  /// of the type in declarations.
  ///
  /// @return Formatted argument
  static EnumArg<ConstStyle> get constStyle =>
      EnumArg<ConstStyle>('const-style');

  /// Sets the enum underlying type
  ///
  /// Specifies the C++ type to use for enums (e.g., "uint8_t", "int").
  ///
  /// @return Formatted argument
  static StringArg get enumType => StringArg('enum-type');

  /// Sets the namespace for generated code
  ///
  /// Specifies the C++ namespace in which to place the generated types.
  ///
  /// @return Formatted argument
  static StringArg get namespace => StringArg('namespace');

  /// Sets the code formatting style
  ///
  /// Controls whether classes are generated with public members or
  /// private members with getter/setter methods.
  ///
  /// @return Formatted argument
  static EnumArg<CodeFormat> get codeFormat =>
      EnumArg<CodeFormat>('code-format');

  /// Sets the include statement style
  ///
  /// Controls whether include statements use local-style quotes
  /// or global-style angle brackets.
  ///
  /// @return Formatted argument
  static EnumArg<IncludeStyle> get includeStyle =>
      EnumArg<IncludeStyle>('include-style');

  /// Sets the source code generation style
  ///
  /// Controls whether the generated code is split into header and
  /// implementation files or combined into a single file.
  ///
  /// @return Formatted argument
  static EnumArg<SourceStyle> get sourceStyle =>
      EnumArg<SourceStyle>('source-style');

  /// Controls the use of Boost libraries
  ///
  /// Determines whether the generated code uses Boost libraries for
  /// certain features. When disabled, standard library alternatives
  /// are used where possible.
  ///
  /// @return Formatted argument
  static BoolArg get boost => BoolArg('boost');

  /// Controls whether null optional values are hidden
  ///
  /// When enabled, optional properties with null values won't be
  /// included in the serialized target.
  ///
  /// @return Formatted argument
  static BoolArg get hideNullOptional => BoolArg('hide-null-optional');

  /// Sets the type naming style
  ///
  /// Controls the naming convention used for type names in the generated code.
  ///
  /// @return Formatted argument
  static EnumArg<NamingStyle> get typeStyle =>
      EnumArg<NamingStyle>('type-style');

  /// Sets the member naming style
  ///
  /// Controls the naming convention used for class members in the generated code.
  ///
  /// @return Formatted argument
  static EnumArg<NamingStyle> get memberStyle =>
      EnumArg<NamingStyle>('member-style');

  /// Sets the enumerator naming style
  ///
  /// Controls the naming convention used for enum values in the generated code.
  ///
  /// @return Formatted argument
  static EnumArg<NamingStyle> get enumeratorStyle =>
      EnumArg<NamingStyle>('enumerator-style');
}
