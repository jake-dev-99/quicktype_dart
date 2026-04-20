import 'package:meta/meta.dart';

import '../config.dart';
import 'renderer_options.dart' show coerceRendererOptionsMap;

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
  String? get defaultPath;
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
  String toString() => name;

  @override
  String? get defaultPath => null;
}

/// Output languages quicktype can generate typed code for.
///
/// Each value carries the CLI flag ([argName]) and its primary file
/// extensions ([extensions]). Pass language-specific options via a
/// [RendererOptions] subclass — e.g. `TargetType.dart` pairs with
/// `DartRendererOptions`.
///
/// Example:
///
/// ```dart
/// await QuicktypeDart.generate(
///   label: 'User',
///   data: [{'id': 1}],
///   target: TargetType.dart,
///   options: const DartRendererOptions(useFreezed: true),
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
  String toString() => name;
}

/// One source or target slot in a quicktype configuration.
///
/// A [TypeConfig] pairs a [TypeEnum] (source format or output language) with
/// an input/output path and any language-specific [rendererOptions].
/// Typically loaded from `quicktype.json` via [TypeConfig.fromJson], but can
/// also be built programmatically.
///
/// Example:
///
/// ```dart
/// const dartTarget = TypeConfig(
///   type: TargetType.dart,
///   path: 'lib/models/',
///   rendererOptions: {'use-freezed': 'true'},
/// );
/// ```
@immutable
class TypeConfig {
  /// The source format or target language for this slot.
  final TypeEnum type;

  /// Input glob pattern (for sources) or output directory (for targets).
  final String path;

  /// Language-specific flags applied to every generation in this slot.
  /// Keys are quicktype-core renderer option names (e.g. `'use-freezed'`);
  /// values are their stringified forms (`'true'`, `'false'`, `'user.g.dart'`,
  /// etc.). See the target-language `*RendererOptions` class for the typed
  /// surface.
  final Map<String, String> rendererOptions;

  const TypeConfig({
    required this.type,
    required this.path,
    this.rendererOptions = const {},
  });

  /// Creates a configuration from JSON data.
  ///
  /// Supported shape:
  /// ```json
  /// { "path": "lib/models/", "args": { "use-freezed": true, "null-safety": true } }
  /// ```
  ///
  /// The `args` object is passed straight through to quicktype-core as
  /// `rendererOptions` — each value is stringified (`true`/`false` for bools,
  /// verbatim for strings).
  factory TypeConfig.fromJson(TypeEnum type, Map<String, dynamic> json) {
    try {
      final path = json['path'] as String? ?? type.defaultPath ?? 'models/';
      final raw = json['args'];
      final rendererOptions = raw is Map<String, dynamic>
          ? coerceRendererOptionsMap(
              raw,
              sectionLabel: '${type.argName} target args',
            )
          : const <String, String>{};

      return TypeConfig(
          type: type, path: path, rendererOptions: rendererOptions);
    } catch (e) {
      if (e is ConfigException) rethrow;
      throw ConfigException('Invalid type configuration', e);
    }
  }

  /// Round-trips to the JSON shape accepted by [TypeConfig.fromJson].
  Map<String, dynamic> toJson() => {
        'type': type.toString(),
        'path': path,
        if (rendererOptions.isNotEmpty) 'args': rendererOptions,
      };
}
