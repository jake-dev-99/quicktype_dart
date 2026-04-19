import '../args.dart';

/// Swift Type specific options for quicktype code generation.
///
/// Provides methods to generate properly formatted command-line arguments
/// for Swift-specific features of quicktype.
@Deprecated('Use SwiftRendererOptions instead — removal planned for v0.4.0')
class SwiftArgs {
  /// Private constructor to prevent instantiation
  SwiftArgs._();

  /// Returns a list of all available Swift-specific arguments
  ///
  /// Useful for documentation or UI purposes
  ///
  /// @return List of argument builders
  static Map<String, Arg> get args => {
        justTypes.name: justTypes,
        structOrClass.name: structOrClass,
        density.name: density,
        initializers.name: initializers,
        codingKeys.name: codingKeys,
        codingKeysProtocol.name: codingKeysProtocol,
        accessLevel.name: accessLevel,
        alamofire.name: alamofire,
        supportLinux.name: supportLinux,
        typePrefix.name: typePrefix,
        protocol.name: protocol,
        acronymStyle.name: acronymStyle,
        objectiveCSupport.name: objectiveCSupport,
        optionalEnums.name: optionalEnums,
        sendable.name: sendable,
        swift5Support.name: swift5Support,
        multiFileTarget.name: multiFileTarget,
        mutableProperties.name: mutableProperties,
      };

  /// Generates plain types without Codable conformance
  ///
  /// When enabled, generated types won't implement Codable protocol
  /// and no serialization/deserialization code will be included.
  ///
  /// @return Formatted argument
  static BoolArg get justTypes => BoolArg('just-types');

  /// Controls whether to generate structs or classes
  ///
  /// @return Formatted argument
  static EnumArg get structOrClass => EnumArg<StructOrClass>('struct-or-class');

  /// Sets the code density of the generated Swift code
  ///
  /// Controls how compact the generated code is, affecting
  /// line breaks and spacing.
  ///
  /// @return Formatted argument
  static EnumArg get density => EnumArg<Density>('density');

  /// Controls generation of initializers and mutators
  ///
  /// When enabled, generates initializers for all types and
  /// mutating methods for structs.
  ///
  /// @return Formatted argument
  static BoolArg get initializers => BoolArg('initializers');

  /// Controls generation of explicit CodingKey values
  ///
  /// When enabled, generates explicit CodingKey enum values in
  /// Codable types for better control over serialization.
  ///
  /// @return Formatted argument
  static BoolArg get codingKeys => BoolArg('coding-keys');

  /// Sets protocols to implement for CodingKeys enum
  ///
  /// @return Formatted argument
  static StringArg get codingKeysProtocol => StringArg('coding-keys-protocol');

  /// Sets the access level for generated types
  ///
  /// Controls whether the types are internal (default) or public.
  ///
  /// @return Formatted argument
  static EnumArg get accessLevel => EnumArg<SwiftAccessLevel>('access-level');

  /// Controls generation of Alamofire extensions
  ///
  /// When enabled, generates extensions for Alamofire compatibility.
  ///
  /// @return Formatted argument
  static BoolArg get alamofire => BoolArg('alamofire');

  /// Controls Linux platform support
  ///
  /// When enabled, ensures generated code is compatible with Swift on Linux.
  ///
  /// @return Formatted argument
  static BoolArg get supportLinux => BoolArg('support-linux');

  /// Sets a prefix for all generated type names
  ///
  /// @return Formatted argument
  static StringArg get typePrefix => StringArg('type-prefix');

  /// Sets the protocols that generated types will implement
  ///
  /// Controls whether types implement additional protocols like
  /// Equatable or Hashable beyond the default Codable.
  ///
  /// @return Formatted argument
  static EnumArg get protocol => EnumArg<SwiftProtocol>('protocol');

  /// Sets the capitalization style for acronyms
  ///
  /// Controls how acronyms like "URL" or "JSON" are capitalized
  /// in type and property names.
  ///
  /// @return Formatted argument
  static EnumArg get acronymStyle => EnumArg<AcronymStyle>('acronym-style');

  /// Controls Objective-C compatibility features
  ///
  /// When enabled, types inherit from NSObject and classes are
  /// marked with @objcMembers.
  ///
  /// @return Formatted argument
  static BoolArg get objectiveCSupport => BoolArg('objective-c-support');

  /// Controls whether enums can be optional
  ///
  /// When enabled, unknown enum values result in null instead of error.
  ///
  /// @return Formatted argument
  static BoolArg get optionalEnums => BoolArg('optional-enums');

  /// Controls whether types are marked as Sendable
  ///
  /// When enabled, adds the Sendable protocol to generated types
  /// for Swift concurrency support.
  ///
  /// @return Formatted argument
  static BoolArg get sendable => BoolArg('sendable');

  /// Controls Swift 5 compatibility mode
  ///
  /// When enabled, generates code compatible with Swift 5.
  ///
  /// @return Formatted argument
  static BoolArg get swift5Support => BoolArg('swift-5-support');

  /// Controls multi-file dest
  ///
  /// When enabled, each top-level type is generated in its own file.
  ///
  /// @return Formatted argument
  static BoolArg get multiFileTarget => BoolArg('multi-file-dest');

  /// Controls property mutability
  ///
  /// When enabled, properties are declared with 'var' instead of 'let'.
  ///
  /// @return Formatted argument
  static BoolArg get mutableProperties => BoolArg('mutable-properties');
}
