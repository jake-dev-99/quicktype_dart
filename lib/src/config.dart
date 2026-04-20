import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:meta/meta.dart';

import 'models/type.dart';
import 'logging.dart';

/// Thrown when a `quicktype.json` can't be parsed or is semantically invalid.
@immutable
class ConfigException implements Exception {
  /// Creates a config-load failure with a human-readable [message] and
  /// an optional underlying [cause].
  const ConfigException(this.message, [this.cause]);

  /// Human-readable description of the failure.
  final String message;

  /// The underlying error, if this exception wraps one.
  final Object? cause;

  @override
  String toString() => cause != null
      ? 'ConfigException: $message\nCaused by: $cause'
      : 'ConfigException: $message';
}

/// Loaded `quicktype.json` (or the built-in defaults). Pure value class —
/// construct one per unit of work; multiple configs can coexist in the
/// same process without stepping on each other.
///
/// Sources are keyed by [SourceType] (json / jsonschema / graphql /
/// typescript) and map to one or more [TypeConfig]s describing where to
/// find input files. Targets are keyed by [TargetType] and describe
/// where generated code lands plus any language-specific renderer
/// options.
///
/// Consumers usually reach [Config] through [Quicktype.new]:
///
/// ```dart
/// final quicktype = Quicktype(Config.loadOrDefaults(path: 'quicktype.json'));
/// await quicktype.executeAll(await quicktype.buildCommandsFromConfig());
/// ```
///
/// For tests or advanced flows, build a `Config` directly via
/// [Config.fromFile], [Config.fromMap], or [Config.defaults].
@immutable
class Config {
  const Config._(this.sources, this.targets);

  /// The default config file name — `quicktype.json`.
  static const String defaultConfigFile = 'quicktype.json';

  /// Default on-disk model directory for generated [TypeConfig]s.
  static const String _defaultModelPath = 'models/';

  /// Input file declarations, keyed by format.
  final Map<SourceType, Set<TypeConfig>> sources;

  /// Output file declarations, keyed by target language.
  final Map<TargetType, Set<TypeConfig>> targets;

  /// Loads a config from [path]. Throws [ConfigException] on parse or
  /// shape errors. The caller is responsible for deciding what to do
  /// when the file is missing — use [Config.loadOrDefaults] for the
  /// "missing = defaults" convenience.
  factory Config.fromFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw ConfigException('Config file "$path" not found.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } catch (e) {
      throw ConfigException('Failed to parse "$path": $e', e);
    }
    if (decoded is! Map<String, dynamic>) {
      throw ConfigException(
        'Config root must be a JSON object, got ${decoded.runtimeType} '
        'in "$path".',
      );
    }
    return Config.fromMap(decoded);
  }

  /// Builds a config from an already-parsed JSON object shape. Useful
  /// for tests and for config pipelines that load from sources other
  /// than the filesystem.
  factory Config.fromMap(Map<String, dynamic> map) {
    return Config._(
      _parseSources(map['sources']),
      _parseTargets(map['targets']),
    );
  }

  /// Returns the built-in default config — every [SourceType] points at
  /// `models/` and every [TargetType] with a [TargetType.defaultPath]
  /// globs for matching files.
  ///
  /// **Side effect:** creates the `models/` directory on disk if missing.
  /// The downstream `Quicktype` orchestrator assumes it exists by the time
  /// commands get built; keeping the mkdir here means CLI users who fall
  /// through to defaults don't hit a confusing "directory not found" on
  /// the first run.
  factory Config.defaults() {
    final modelDir = Directory(_defaultModelPath);
    if (!modelDir.existsSync()) {
      modelDir.createSync(recursive: true);
      Log.info('Created default models directory at: ${modelDir.path}');
    }
    return Config._(
      _defaultSources(modelDir.path),
      _defaultTargets(),
    );
  }

  /// Convenience for the common "load from disk, fall back to defaults
  /// if absent or unparseable" flow used by the CLI.
  ///
  /// With [strict] = `false` (the default), a missing or malformed file
  /// logs a warning and silently falls back to [Config.defaults]. With
  /// [strict] = `true`, a malformed file rethrows [ConfigException] so
  /// the caller can surface the real parse error — useful for CLI
  /// invocations where "silently ran with defaults" is surprising. A
  /// missing file still falls back in both modes.
  factory Config.loadOrDefaults({
    String path = defaultConfigFile,
    bool strict = false,
  }) {
    final file = File(path);
    if (!file.existsSync()) {
      Log.info('Config file "$path" not found. Loading defaults...');
      return Config.defaults();
    }
    try {
      return Config.fromFile(path);
    } on ConfigException catch (e) {
      if (strict) rethrow;
      Log.warning('Failed to load config file "$path": $e. Using defaults.');
      return Config.defaults();
    }
  }

  static Map<SourceType, Set<TypeConfig>> _defaultSources(String modelPath) {
    return {
      for (final source in SourceType.values)
        source: {
          TypeConfig(path: modelPath, type: source),
        },
    };
  }

  static Map<TargetType, Set<TypeConfig>> _defaultTargets() {
    final targets = <TargetType, Set<TypeConfig>>{};
    for (final target in TargetType.values) {
      targets[target] = _detectFilesForTarget(target);
    }
    return targets;
  }

  static Set<TypeConfig> _detectFilesForTarget(TargetType target) {
    final configs = <TypeConfig>{};
    final pattern = target.defaultPath;
    if (pattern == null) return configs;
    try {
      for (final entity in Glob(pattern).listSync()) {
        configs.add(TypeConfig(path: entity.path, type: target));
      }
    } on FormatException catch (e) {
      Log.warning(
        'Invalid glob pattern in DefaultPaths.${target.name} '
        '("$pattern"): $e. Skipping ${target.name}.',
      );
    } on FileSystemException catch (e) {
      Log.warning(
        'Filesystem error expanding ${target.name} defaults '
        '("$pattern"): $e. Skipping ${target.name}.',
      );
    }
    return configs;
  }

  static Map<SourceType, Set<TypeConfig>> _parseSources(dynamic sourcesMap) {
    if (sourcesMap == null) {
      Log.warning('Sources missing in config file. Using default sources.');
      return _defaultSources(_defaultModelPath);
    }
    if (sourcesMap is! Map<String, dynamic>) {
      throw ConfigException(
        '"sources" must be an object, got ${sourcesMap.runtimeType}.',
      );
    }
    return _parseTypeConfigs<SourceType>(
      sourcesMap,
      SourceType.values,
      'source',
    );
  }

  static Map<TargetType, Set<TypeConfig>> _parseTargets(dynamic targetsMap) {
    if (targetsMap == null) {
      Log.warning('Targets missing in config file. Using default targets.');
      return _defaultTargets();
    }
    if (targetsMap is! Map<String, dynamic>) {
      throw ConfigException(
        '"targets" must be an object, got ${targetsMap.runtimeType}.',
      );
    }
    return _parseTypeConfigs<TargetType>(
      targetsMap,
      TargetType.values,
      'target',
    );
  }

  static Map<T, Set<TypeConfig>> _parseTypeConfigs<T extends TypeEnum>(
    Map<String, dynamic> configMap,
    List<T> validTypes,
    String section,
  ) {
    final result = <T, Set<TypeConfig>>{};
    for (final entry in configMap.entries) {
      final type = _findTypeByKey(entry.key, validTypes, section);
      result[type] = _parseConfigList(entry.key, entry.value, type, section);
    }
    return result;
  }

  /// Resolves [key] against [validTypes], matching on either `name` or
  /// `argName` case-insensitively. Throws [ConfigException] on no match.
  static T _findTypeByKey<T extends TypeEnum>(
    String key,
    List<T> validTypes,
    String section,
  ) {
    final lower = key.toLowerCase();
    for (final t in validTypes) {
      if (t.toString().toLowerCase() == lower ||
          t.argName.toLowerCase() == lower) {
        return t;
      }
    }
    final names = validTypes.map((t) => t.argName).join(', ');
    throw ConfigException(
      'Unknown $section "$key". Expected one of: $names.',
    );
  }

  /// Parses the list of [TypeConfig] entries under a single source/target
  /// key. Throws [ConfigException] when the value shape is wrong.
  static Set<TypeConfig> _parseConfigList<T extends TypeEnum>(
    String key,
    Object? rawList,
    T type,
    String section,
  ) {
    if (rawList is! List) {
      throw ConfigException(
        '"$section.$key" must be a list, got ${rawList.runtimeType}.',
      );
    }
    final configs = <TypeConfig>{};
    for (final entry in rawList) {
      if (entry is! Map<String, dynamic>) {
        throw ConfigException(
          '"$section.$key[]" entries must be objects, got '
          '${entry.runtimeType}.',
        );
      }
      configs.add(TypeConfig.fromJson(type, entry));
    }
    return configs;
  }
}
