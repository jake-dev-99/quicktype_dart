import '../args.dart';

/// C language specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for C-specific features of quicktype.
@Deprecated('Use CRendererOptions instead — removal planned for v0.4.0')
class CArgs {
  /// Private constructor to prevent instantiation
  CArgs._();

  /// Returns a list of all available C-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return List of argument builders
  static Map<String, Arg> get args => {
        printStyle.name: printStyle,
        hashtableSize.name: hashtableSize,
        typedefAlias.name: typedefAlias,
        sourceStyle.name: sourceStyle,
        integerSize.name: integerSize,
        typeStyle.name: typeStyle,
        memberStyle.name: memberStyle,
        enumeratorStyle.name: enumeratorStyle,
      };

  /// Sets the print style for generated code
  ///
  /// Controls whether the generated C code is formatted with proper
  /// indentation (default) or generated without formatting.
  ///
  /// @return Formatted argument
  static EnumArg get printStyle => EnumArg<PrintStyle>('print-style');

  /// Sets the hashtable size for string tables
  ///
  /// Determines the size of hashtables used in the generated code.
  /// Higher values may improve performance but increase code size.
  /// Default is 64.
  ///
  /// @return Formatted argument
  static StringArg get hashtableSize => StringArg('hashtable-size');

  /// Sets typedef alias behavior
  ///
  /// Controls whether the generated code uses C typedefs for structure types.
  ///
  /// @return Formatted argument
  static EnumArg get typedefAlias => EnumArg<TypedefAlias>('typedef-alias');

  /// Sets the source style
  ///
  /// Controls whether the generated code is split into header and implementation
  /// files or combined into a single source file.
  ///
  /// @return Formatted argument
  static EnumArg get sourceStyle => EnumArg<SourceStyle>('source-style');

  /// Sets the integer size
  ///
  /// Determines which C integer type to use for JSON integer values.
  /// Default is int64_t.
  ///
  /// @return Formatted argument
  static EnumArg get integerSize => EnumArg<IntegerSize>('integer-size');

  /// Sets the type naming style
  ///
  /// Controls the naming convention used for type names in the generated code.
  ///
  /// @return Formatted argument
  static EnumArg get typeStyle => EnumArg<NamingStyle>('type-style');

  /// Sets the member naming style
  ///
  /// Controls the naming convention used for struct members in the generated code.
  ///
  /// @return Formatted argument
  static EnumArg get memberStyle => EnumArg<NamingStyle>('member-style');

  /// Sets the enumerator naming style
  ///
  /// Controls the naming convention used for enum values in the generated code.
  ///
  /// @return Formatted argument
  static EnumArg get enumeratorStyle =>
      EnumArg<NamingStyle>('enumerator-style');
}
