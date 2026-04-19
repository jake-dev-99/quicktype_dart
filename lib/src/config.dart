import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:meta/meta.dart';

import 'models/type.dart';
import 'utils/logging.dart';

/// Thrown when a `quicktype.json` can't be parsed or is semantically invalid.
@immutable
class ConfigException implements Exception {
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
/// final quicktype = Quicktype(Config.loadOrDefaults('quicktype.json'));
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
    final dynamic decoded;
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
  factory Config.defaults() {
    // The legacy singleton also created `models/` on disk here; preserve
    // that behavior since build.yaml setups rely on the directory
    // existing by the time commands are built.
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
  factory Config.loadOrDefaults([String path = defaultConfigFile]) {
    final file = File(path);
    if (!file.existsSync()) {
      Log.info('Config file "$path" not found. Loading defaults...');
      return Config.defaults();
    }
    try {
      return Config.fromFile(path);
    } on ConfigException catch (e) {
      Log.info('Failed to load config file "$path": $e. Using defaults.');
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
      final files = Glob(pattern).listSync();
      for (final entity in files) {
        configs.add(TypeConfig(path: entity.path, type: target));
      }
    } catch (e) {
      Log.warning('Could not detect files for ${target.name}: $e');
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
      final key = entry.key.toLowerCase();
      T? matchingType;
      for (final validType in validTypes) {
        if (validType.toString().toLowerCase() == key ||
            validType.argName.toLowerCase() == key) {
          matchingType = validType;
          break;
        }
      }
      if (matchingType == null) {
        final names =
            validTypes.map((t) => t.argName).toList(growable: false).join(', ');
        throw ConfigException(
          'Unknown $section "${entry.key}". Expected one of: $names.',
        );
      }
      final rawList = entry.value;
      if (rawList is! List) {
        throw ConfigException(
          '"$section.${entry.key}" must be a list, got ${rawList.runtimeType}.',
        );
      }
      final configs = <TypeConfig>{};
      for (final config in rawList) {
        if (config is! Map<String, dynamic>) {
          throw ConfigException(
            '"$section.${entry.key}[]" entries must be objects, got '
            '${config.runtimeType}.',
          );
        }
        configs.add(TypeConfig.fromJson(matchingType, config));
      }
      result[matchingType] = configs;
    }

    return result;
  }
}
