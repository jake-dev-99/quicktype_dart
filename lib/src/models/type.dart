import '../config.dart';
import '../utils/logging.dart';
import 'args.dart';

/// Conventional output directories for common target languages, used when
/// a [TypeConfig] doesn't specify an explicit `path`.
class DefaultPaths {
  /// Private — use the static constants.
  DefaultPaths._();

  static const String c = 'src/**/models';
  static const String dart = 'lib/**/models';
  static const String kotlin = 'android/app/src/main/kotlin/**/models/';
  static const String java = 'android/app/src/main/java/**/models/';
  static const String swift = 'ios/**/models/';
  static const String web = 'web/**/models/';
}

/// Common interface implemented by both [SourceType] and [TargetType].
///
/// Lets config-loading and path-resolution code treat either side uniformly.
abstract class TypeEnum {
  /// The CLI flag name quicktype recognizes for this type — e.g. `'dart'`,
  /// `'cs'` (C#), `'py'` (Python).
  String get argName;

  /// File extensions (with leading dot) associated with this type.
  Set<String> get extensions;

  /// Default output path when none is given in config, or `null` if this
  /// type doesn't carry a conventional default (e.g. source types).
  get defaultPath;

  /// The CLI arg registry for this type, keyed by flag name. Produced by
  /// the language-specific `*Args` class (e.g. [DartArgs.args] for
  /// [TargetType.dart]).
  Map<String, Arg> get args;
}

/// Input formats quicktype can infer types from.
enum SourceType implements TypeEnum {
  /// JSON sample data. Most common input.
  json('json', {'.json'}),

  /// JSON Schema describing the shape explicitly.
  jsonschema('schema', {'.schema.json'}),

  /// GraphQL schema.
  graphql('graphql', {'.graphqls', '.graphql'}),

  /// TypeScript type declarations.
  typescript('typescript', {'.ts'});

  const SourceType(this.argName, this.extensions);

  @override
  final String argName;

  @override
  final Set<String> extensions;

  @override
  Map<String, Arg> get args => const {};

  @override
  String toString() => name;

  @override
  get defaultPath => null;
}

/// Output languages quicktype can generate typed code for.
///
/// Each value carries the CLI flag ([argName]), its primary file extensions
/// ([extensions]), and its typed argument registry ([args] — e.g.
/// `TargetType.dart.args` returns [DartArgs.args]).
///
/// Example:
///
/// ```dart
/// // Generate Dart with freezed annotations.
/// await QuicktypeDart.generate(
///   label: 'User',
///   data: [{'id': 1}],
///   target: TargetType.dart,
///   args: [DartArgs.useFreezed..value = true],
/// );
/// ```
enum TargetType implements TypeEnum {
  dart('dart', {'.dart'}),
  c('c', {'.c', '.h'}),
  cpp('cpp', {'.cpp', '.h', '.hpp'}),
  csharp('cs', {'.cs'}),
  elixir('elixir', {'.ex'}),
  elm('elm', {'.elm'}),
  flow('flow', {'.js'}),
  go('go', {'.go'}),
  haskell('haskell', {'.hs'}),
  java('java', {'.java'}),
  javascript('js', {'.js'}),
  kotlin('kotlin', {'.kt'}),
  objc('objc', {'.m'}),
  php('php', {'.php'}),
  proptypes('javascript-prop-types', {'.js'}),
  python('py', {'.py'}),
  ruby('ruby', {'.rb'}),
  rust('rs', {'.rs'}),
  scala('scala3', {'.scala'}),
  smithy('Smithy', {'.smithy'}),
  swift('swift', {'.swift'}),
  typescript('ts', {'.ts'}),
  ;

  const TargetType(this.argName, this.extensions);

  @override
  final String argName;

  @override
  final Set<String> extensions;

  /// Conventional output directory for this language, or `null` if none.
  /// See [DefaultPaths] for the directory conventions.
  @override
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
      case TargetType.csharp:
        return CSharpArgs.args;
      case TargetType.elixir:
        return ElixirArgs.args;
      case TargetType.elm:
        return ElmArgs.args;
      case TargetType.flow:
        return FlowArgs.args;
      case TargetType.go:
        return GoArgs.args;
      case TargetType.haskell:
        return HaskellArgs.args;
      case TargetType.java:
        return JavaArgs.args;
      case TargetType.javascript:
        return JavaScriptArgs.args;
      case TargetType.kotlin:
        return KotlinArgs.args;
      case TargetType.objc:
        return ObjectiveCArgs.args;
      case TargetType.php:
        return PHPArgs.args;
      case TargetType.proptypes:
        return PropTypesArgs.args;
      case TargetType.python:
        return PythonArgs.args;
      case TargetType.ruby:
        return RubyArgs.args;
      case TargetType.rust:
        return RustArgs.args;
      case TargetType.scala:
        return Scala3Args.args;
      case TargetType.smithy:
        return SmithyArgs.args;
      case TargetType.swift:
        return SwiftArgs.args;
      case TargetType.typescript:
        return TypeScriptArgs.args;
    }
  }

  @override
  String toString() => name;
}

/// One source or target slot in a quicktype configuration.
///
/// A [TypeConfig] pairs a [TypeEnum] (source format or output language) with
/// an output/input path and any language-specific [args]. Typically loaded
/// from `quicktype.json` via [TypeConfig.fromJson], but can also be built
/// programmatically.
///
/// Example:
///
/// ```dart
/// final dartTarget = TypeConfig(
///   type: TargetType.dart,
///   path: 'lib/models/',
///   args: [DartArgs.useFreezed..value = true],
/// );
/// ```
class TypeConfig {
  /// The source format or target language for this slot.
  final TypeEnum type;

  /// Input glob pattern (for sources) or output directory (for targets).
  final String path;

  /// Language-specific flags applied to every generation in this slot.
  final List<Arg> args;

  const TypeConfig({
    required this.type,
    required this.path,
    this.args = const [],
  });

  /// Creates a configuration from JSON data.
  ///
  /// Supported shape:
  /// ```json
  /// { "path": "lib/models/", "args": { "use-freezed": true, "null-safety": true } }
  /// ```
  ///
  /// Arg keys are matched against [type.args] (the language's registered arg
  /// names). Unknown keys are ignored with a log warning. Values are coerced
  /// to the matching [Arg] subtype: booleans for [BoolArg]/[SimpleArg],
  /// strings for [StringArg], and enum-name strings for [EnumArg].
  factory TypeConfig.fromJson(TypeEnum type, Map<String, dynamic> json) {
    try {
      final path = json['path'] as String? ?? type.defaultPath ?? 'models/';
      final argsJson = json['args'];
      final args = argsJson is Map<String, dynamic>
          ? _parseArgs(type, argsJson)
          : const <Arg>[];

      return TypeConfig(type: type, path: path, args: args);
    } catch (e) {
      if (e is ConfigException) rethrow;
      throw ConfigException('Invalid type configuration', e);
    }
  }

  static List<Arg> _parseArgs(TypeEnum type, Map<String, dynamic> argsJson) {
    final registry = type.args;
    final out = <Arg>[];
    for (final entry in argsJson.entries) {
      final arg = registry[entry.key];
      if (arg == null) {
        Log.warning(
          'Unknown arg "${entry.key}" for ${type.argName}; ignoring.',
          'TypeConfig',
        );
        continue;
      }
      _assignArgValue(arg, entry.value);
      out.add(arg);
    }
    return out;
  }

  static void _assignArgValue(Arg arg, dynamic value) {
    if (arg is BoolArg || arg is SimpleArg) {
      if (value is bool) {
        (arg as dynamic).value = value;
      }
    } else if (arg is StringArg) {
      if (value is String) arg.value = value;
    } else if (arg is EnumArg) {
      // Config supplies the enum's toString() value. Without enum introspection
      // at runtime, we can't map a string back to the T — consumers needing
      // enum args from JSON should set them programmatically for now.
      Log.warning(
        'EnumArg "${arg.name}" cannot be set from JSON; set programmatically.',
        'TypeConfig',
      );
    }
  }

  /// Round-trips to the JSON shape accepted by [TypeConfig.fromJson].
  /// Only args with a non-null value are included.
  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'path': path,
        if (args.isNotEmpty)
          'args': {
            for (final a in args)
              if (a.value != null) a.name: a.value,
          },
      };
}
