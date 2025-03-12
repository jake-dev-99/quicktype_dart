import '../config.dart';
import 'args.dart';

/// Default paths for common target languages
class DefaultPaths {
  static const String c = 'src/**/models';
  static const String dart = 'lib/**/models';
  static const String kotlin = 'android/app/src/main/kotlin/**/models/';
  static const String java = 'android/app/src/main/java/**/models/';
  static const String swift = 'ios/**/models/';
  static const String web = 'web/**/models/';

  // Private constructor to prevent instantiation
  DefaultPaths._();
}

/// Common interface for type enumerations
abstract class TypeEnum {
  /// Command-line argument name to specify this type
  String get argName;

  /// File extensions associated with this type
  Set<String> get extensions;

  get defaultPath;

  /// Available command-line arguments for this type
  Map<String, Arg> get args;
}

/// Supported source types for quicktype
enum SourceType implements TypeEnum {
  json('json', {'.json'}),
  jsonschema('schema', {'.schema.json'}),
  graphql('graphql', {'.graphqls', '.graphql'}),
  typescript('typescript', {'.ts'});

  const SourceType(this.argName, this.extensions);
  final String argName;
  final Set<String> extensions;

  @override
  Map<String, Arg> get args => {};

  @override
  String toString() => name;

  @override
  get defaultPath => null;
}

/// Supported target languages for quicktype
enum TargetType implements TypeEnum {
  dart('dart', {'.dart'}),
  c('c', {'.c', '.h'}),
  cpp('cpp', {'.cpp', '.h', '.hpp'}),
  java('java', {'.java'}),
  javascript('js', {'.js'}),
  kotlin('kotlin', {'.kt'}),
  objc('objc', {'.m'}),
  swift('swift', {'.swift'}),
  typescript('ts', {'.ts'}),
  ;

  const TargetType(this.argName, this.extensions);
  final String argName;
  final Set<String> extensions;

  /// Get default path for this target type if one exists
  String? get defaultPath {
    switch (this) {
      case TargetType.dart:
        return DefaultPaths.dart;
      case TargetType.kotlin:
        return DefaultPaths.kotlin;
      case TargetType.java:
        return DefaultPaths.java;
      case TargetType.swift:
        return DefaultPaths.swift;
      case TargetType.javascript || TargetType.typescript:
        return DefaultPaths.web;
      default:
        return null;
    }
  }

  @override
  Map<String, Arg> get args {
    switch (this) {
      case TargetType.dart:
        return DartArgs.args;
      case TargetType.c:
        return CArgs.args;
      case TargetType.cpp:
        return CppArgs.args;
      case TargetType.java:
        return JavaArgs.args;
      case TargetType.javascript:
        return JavaScriptArgs.args;
      case TargetType.kotlin:
        return KotlinArgs.args;
      case TargetType.objc:
        return ObjectiveCArgs.args;
      case TargetType.swift:
        return SwiftArgs.args;
      case TargetType.typescript:
        return TypeScriptArgs.args;
    }
  }

  @override
  String toString() => name;
}

/// Defines settings for a source or target in the quicktype configuration
class TypeConfig {
  /// The type of source or target
  final TypeEnum type;

  /// The output path for generated files
  final String path;

  /// Creates a new type configuration
  const TypeConfig({required this.type, required this.path});

  /// Creates a configuration from JSON data
  factory TypeConfig.fromJson(TypeEnum type, Map<String, dynamic> json) {
    try {
      // Get path with fallback to default
      final path = json['path'] as String? ?? type.defaultPath ?? 'models/';

      return TypeConfig(
        type: type,
        path: path,
      );
    } catch (e) {
      if (e is ConfigException) rethrow;
      throw ConfigException('Invalid target configuration', e);
    }
  }

  /// Converts configuration to JSON
  Map<String, dynamic> toJson() => {
        'type': type,
        'path': path,
      };
}
