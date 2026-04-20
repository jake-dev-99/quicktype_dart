// ignore_for_file: public_member_api_docs
/// Typed enums used by the language-specific `*RendererOptions` classes
/// (see `lib/src/models/options/lang_*.dart`) for options that accept a
/// bounded set of values — e.g.
/// `CSharpRendererOptions(framework: CSharpFramework.netstandard)`.
///
/// Each enum's `toString()` returns the exact string quicktype-core's
/// `rendererOptions` expects for that flag.
library;

//===== SHARED ENUMS =====

/// HTTP method options for API endpoints
// (used by the corresponding *RendererOptions class)
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options;

  @override
  String toString() => name;
}

/// Debug options for quicktype command-line interface.
/// Global across all target languages.
enum DebugArgs {
  /// Prints the type inference graph
  printGraph('print-graph'),

  /// Prints reconstitution information
  printReconstitution('print-reconstitution'),

  /// Prints name gathering information
  printGatherNames('print-gather-names'),

  /// Prints transformation information
  printTransformations('print-transformations'),

  /// Prints schema resolving information
  printSchemaResolving('print-schema-resolving'),

  /// Prints timing information
  printTimes('print-times'),

  /// Enables provenance tracking
  provenance('provenance'),

  /// Enables all debug options
  all(null);

  const DebugArgs(this.flag);
  final String? flag;

  @override
  String toString() {
    if (this == all) {
      return DebugArgs.values
          .where((e) => e != DebugArgs.all)
          .map((e) => e.flag)
          .join(',');
    }

    if (flag == null || flag!.isEmpty) {
      throw ArgumentError('Debug argument $this is not supported');
    }

    return flag!;
  }
}

/// Converter generation options
// (used by the corresponding *RendererOptions class)
enum ConverterType {
  /// Generate converters only for top-level types
  topLevel('top-level'),

  /// Generate converters for all object types
  allObjects('all-objects');

  /// The converter type option value
  final String value;

  /// Creates a new converter type option
  const ConverterType(this.value);

  @override
  String toString() => value;
}

/// Raw input type options
// (used by the corresponding *RendererOptions class)
enum RawType {
  /// Use 'json' as the raw input type
  json('json'),

  /// Use 'any' as the raw input type
  any('any');

  /// The raw type option value
  final String value;

  /// Creates a new raw type option
  const RawType(this.value);

  @override
  String toString() => value;
}

/// Array type options
// (used by the corresponding *RendererOptions class)
enum ArrayType {
  /// Use native array types (`T[]`).
  array('array'),

  /// Use collection types (`List<T>`).
  list('list');

  /// The array type option value
  final String value;

  /// Creates a new array type option
  const ArrayType(this.value);

  @override
  String toString() => value;
}

/// Acronym style options for property naming
// (used by the corresponding *RendererOptions class)
enum AcronymStyle {
  /// Keep acronyms as they appear in JSON
  original('original'),

  /// Format acronyms in PascalCase (e.g., XmlHttp)
  pascal('pascal'),

  /// Format acronyms in camelCase (e.g., xmlHttp)
  camel('camel'),

  /// Format acronyms in lowercase (e.g., xmlhttp)
  lowerCase('lowerCase'),

  /// Format acronyms in UPPERCASE (e.g., XMLHTTP)
  upperCase('upperCase');

  /// The acronym style option value
  final String value;

  /// Creates a new acronym style option
  const AcronymStyle(this.value);

  @override
  String toString() => value;
}

/// Naming style options for code identifiers
// (used by the corresponding *RendererOptions class)
enum NamingStyle {
  /// Use pascal case (MyIdentifier)
  pascalCase('pascal-case'),

  /// Use camel case (myIdentifier)
  camelCase('camel-case'),

  /// Use snake case (my_identifier)
  snakeCase('snake-case'),

  /// Use upper snake case (MY_IDENTIFIER)
  upperSnakeCase('upper-snake-case'),

  /// Use kebab case (my-identifier)
  kebabCase('kebab-case'),

  /// Use upper kebab case (MY-IDENTIFIER)
  upperKebabCase('upper-kebab-case'),

  /// Use underscore case (my_identifier) - alias for snake case
  underscoreCase('underscore-case'),

  /// Use upper underscore case (MY_IDENTIFIER) - alias for upper snake case
  upperUnderscoreCase('upper-underscore-case'),

  /// Use pascal case with upper acronyms (XMLHttpRequest)
  pascalCaseUpperAcronyms('pascal-case-upper-acronyms'),

  /// Use camel case with upper acronyms (xmlHTTPRequest)
  camelCaseUpperAcronyms('camel-case-upper-acronyms');

  /// The naming style option value
  final String value;
  const NamingStyle(this.value);

  @override
  String toString() => value;
}

/// Source code organization options
// (used by the corresponding *RendererOptions class)
enum SourceStyle {
  /// Generate a single source file
  singleSource('single-source'),

  /// Generate multiple source files
  multiSource('multi-source'),

  /// Generate separate header and implementation files
  splitHeader('split-header');

  /// The source style option value
  final String value;
  const SourceStyle(this.value);

  @override
  String toString() => value;
}

/// Code density options
// (used by the corresponding *RendererOptions class)
enum Density {
  /// Standard spacing and line breaks for readability
  normal('normal'),

  /// More compact code with fewer line breaks
  dense('dense');

  /// The density option value
  final String value;
  const Density(this.value);

  @override
  String toString() => value;
}

//===== C LANGUAGE SPECIFIC ENUMS =====

/// Integer size type for C code generation
// (used by the corresponding *RendererOptions class)
enum IntegerSize {
  /// Use 8-bit integers (int8_t)
  int8('int8_t'),

  /// Use 16-bit integers (int16_t)
  int16('int16_t'),

  /// Use 32-bit integers (int32_t)
  int32('int32_t'),

  /// Use 64-bit integers (int64_t) - default option
  int64('int64_t');

  /// The C type name to use
  final String value;
  const IntegerSize(this.value);

  @override
  String toString() => value;
}

/// Typedef alias option for C code generation
// (used by the corresponding *RendererOptions class)
enum TypedefAlias {
  /// Don't generate typedefs (default)
  noTypedef('no-typedef'),

  /// Generate typedefs for each type
  addTypedef('add-typedef');

  /// The typedef option value
  final String value;
  const TypedefAlias(this.value);

  @override
  String toString() => value;
}

/// Print style option for C code generation
// (used by the corresponding *RendererOptions class)
enum PrintStyle {
  /// Format the code with proper indentation (default)
  formatted('print-formatted'),

  /// Generate code without extra formatting
  unformatted('print-unformatted');

  /// The print style option value
  final String value;
  const PrintStyle(this.value);

  @override
  String toString() => value;
}

//===== C++ LANGUAGE SPECIFIC ENUMS =====

/// C++ code format options for quicktype generation
// (used by the corresponding *RendererOptions class)
enum CodeFormat {
  /// Generate classes with public member variables
  withStruct('with-struct'),

  /// Generate classes with private members and getter/setter methods
  withGetterSetter('with-getter-setter');

  /// The code format option value
  final String value;
  const CodeFormat(this.value);

  @override
  String toString() => value;
}

/// String type handling options for C++ code generation
// (used by the corresponding *RendererOptions class)
enum WStringType {
  /// Use standard std::string (UTF-8)
  useString('use-string'),

  /// Use std::wstring (wide character string)
  useWString('use-wstring');

  /// The string type option value
  final String value;
  const WStringType(this.value);

  @override
  String toString() => value;
}

/// Const placement style for C++ code generation
// (used by the corresponding *RendererOptions class)
enum ConstStyle {
  /// Place const to the left of the type (const Type)
  westConst('west-const'),

  /// Place const to the right of the type (Type const)
  eastConst('east-const');

  /// The const style option value
  final String value;
  const ConstStyle(this.value);

  @override
  String toString() => value;
}

/// Include statement style for C++ code generation
// (used by the corresponding *RendererOptions class)
enum IncludeStyle {
  /// Use quotes for includes ("header.h")
  localInclude('local-include'),

  /// Use angle brackets for includes (`<header.h>`).
  globalInclude('global-include');

  /// The include style option value
  final String value;
  const IncludeStyle(this.value);

  @override
  String toString() => value;
}

//===== C# LANGUAGE SPECIFIC ENUMS =====

/// C# serialization framework options
// (used by the corresponding *RendererOptions class)
enum CSharpFramework {
  /// Use Newtonsoft.Json for serialization (JSON.NET)
  newtonSoft('NewtonSoft'),

  /// Use System.Text.Json for serialization
  systemTextJson('SystemTextJson');

  final String value;
  const CSharpFramework(this.value);

  @override
  String toString() => value;
}

/// C# version options
// (used by the corresponding *RendererOptions class)
enum CSharpVersion {
  /// Target C# 5.0
  v5('5'),

  /// Target C# 6.0
  v6('6');

  final String value;
  const CSharpVersion(this.value);

  @override
  String toString() => value;
}

/// Number type options for C#
// (used by the corresponding *RendererOptions class)
enum NumberType {
  /// Use double for numeric values
  double('double'),

  /// Use decimal for numeric values
  decimal('decimal');

  final String value;
  const NumberType(this.value);

  @override
  String toString() => value;
}

/// Any type options for C#
// (used by the corresponding *RendererOptions class)
enum AnyType {
  /// Use object type for any/dynamic values
  object('object'),

  /// Use dynamic type for any/dynamic values
  dynamic('dynamic');

  final String value;
  const AnyType(this.value);

  @override
  String toString() => value;
}

/// Target features options for C#
// (used by the corresponding *RendererOptions class)
enum Features {
  /// Generate complete serialization support
  complete('complete'),

  /// Generate only attributes
  attributesOnly('attributes-only'),

  /// Generate just types and namespace
  justTypesAndNamespace('just-types-and-namespace'),

  /// Generate just types
  justTypes('just-types');

  final String value;
  const Features(this.value);

  @override
  String toString() => value;
}

/// Base class options for C#
// (used by the corresponding *RendererOptions class)
enum BaseClass {
  /// Use EntityData as base class
  entityData('EntityData'),

  /// Use Object as base class
  object('Object');

  final String value;
  const BaseClass(this.value);

  @override
  String toString() => value;
}

//===== JAVA LANGUAGE SPECIFIC ENUMS =====

/// Date time provider options for Java code generation
// (used by the corresponding *RendererOptions class)
enum DateTimeProvider {
  /// Use Java 8 java.time.* classes (modern approach)
  java8('java8'),

  /// Use legacy java.util.Date class
  legacy('legacy');

  /// The date time provider option value
  final String value;
  const DateTimeProvider(this.value);

  @override
  String toString() => value;
}

//===== KOTLIN LANGUAGE SPECIFIC ENUMS =====

/// Serialization framework options for Kotlin code generation
// (used by the corresponding *RendererOptions class)
enum KotlinFramework {
  /// Generate types only without serialization code
  justTypes('just-types'),

  /// Use Jackson for JSON serialization
  jackson('jackson'),

  /// Use Klaxon for JSON serialization
  klaxon('klaxon'),

  /// Use kotlinx.serialization for JSON serialization
  kotlinx('kotlinx');

  /// The framework option value
  final String value;
  const KotlinFramework(this.value);

  @override
  String toString() => value;
}

//===== OBJECTIVE-C LANGUAGE SPECIFIC ENUMS =====

/// Features options for Objective-C code generation
// (used by the corresponding *RendererOptions class)
enum ObjectiveCFeatures {
  /// Generate both interface (.h) and implementation (.m) files
  all('all'),

  /// Generate only interface (.h) files
  interface('interface'),

  /// Generate only implementation (.m) files
  implementation('implementation');

  /// The features option value
  final String value;
  const ObjectiveCFeatures(this.value);

  @override
  String toString() => value;
}

//===== PYTHON LANGUAGE SPECIFIC ENUMS =====

/// Python version options for code generation
// (used by the corresponding *RendererOptions class)
enum PythonVersion {
  /// Target Python 3.5 compatibility
  v35('3.5'),

  /// Target Python 3.6 compatibility (enables f-strings, etc.)
  v36('3.6'),

  /// Target Python 3.7+ compatibility (enables data classes, etc.)
  v37('3.7');

  /// The version option value
  final String value;
  const PythonVersion(this.value);

  @override
  String toString() => value;
}

//===== RUBY LANGUAGE SPECIFIC ENUMS =====

/// Type strictness options for Ruby code generation
// (used by the corresponding *RendererOptions class)
enum RubyStrictness {
  /// Generate strict type checking (uses dry-types strict)
  strict('strict'),

  /// Generate coercible type checking (uses dry-types with coercion)
  coercible('coercible'),

  /// No type checking (plain Ruby objects)
  none('none');

  /// The strictness option value
  final String value;
  const RubyStrictness(this.value);

  @override
  String toString() => value;
}

//===== RUST LANGUAGE SPECIFIC ENUMS =====

/// Field visibility options for Rust code generation
// (used by the corresponding *RendererOptions class)
enum RustVisibility {
  /// Private fields (no visibility modifier)
  private,

  /// Crate-visible fields (pub(crate))
  crate,

  /// Public fields (pub)
  public;

  @override
  String toString() => name;
}

//===== SCALA LANGUAGE SPECIFIC ENUMS =====

/// Serialization framework options for Scala 3 code generation
// (used by the corresponding *RendererOptions class)
enum Scala3Framework {
  /// Generate types only without serialization code
  justTypes('just-types'),

  /// Use Circe for JSON serialization
  circe('circe'),

  /// Use uPickle for JSON serialization
  upickle('upickle');

  /// The framework option value
  final String value;
  const Scala3Framework(this.value);

  @override
  String toString() => value;
}

//===== SWIFT LANGUAGE SPECIFIC ENUMS =====

/// Options for defining Swift type as struct or class
// (used by the corresponding *RendererOptions class)
enum StructOrClass {
  /// Use structs for generated types (value semantics)
  struct('struct'),

  /// Use classes for generated types (reference semantics)
  class_('class');

  /// The struct-or-class option value
  final String value;
  const StructOrClass(this.value);

  @override
  String toString() => value;
}

/// Access level options for Swift code generation
// (used by the corresponding *RendererOptions class)
enum SwiftAccessLevel {
  /// Use 'internal' access level (visible within module)
  internal('internal'),

  /// Use 'public' access level (visible from other modules)
  public('public');

  /// The access level option value
  final String value;
  const SwiftAccessLevel(this.value);

  @override
  String toString() => value;
}

/// Protocol implementation options for Swift code generation
// (used by the corresponding *RendererOptions class)
enum SwiftProtocol {
  /// Don't implement additional protocols beyond Codable
  none('none'),

  /// Make types implement Equatable protocol
  equatable('equatable'),

  /// Make types implement Hashable protocol (implies Equatable)
  hashable('hashable');

  /// The protocol option value
  final String value;
  const SwiftProtocol(this.value);

  @override
  String toString() => value;
}
