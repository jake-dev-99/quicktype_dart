import 'dart:convert';
import 'dart:io';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'models/type.dart';
import 'utils/logging.dart';

/// Thrown when a `quicktype.json` can't be parsed or is semantically invalid.
class ConfigException implements Exception {
  /// Human-readable description of the failure.
  final String message;

  /// The underlying error, if this exception wraps one.
  final Object? cause;

  const ConfigException(this.message, [this.cause]);

  @override
  String toString() => cause != null
      ? 'ConfigException: $message\nCaused by: $cause'
      : 'ConfigException: $message';
}

/// Singleton holder for a loaded `quicktype.json` (or the built-in defaults).
///
/// Sources are keyed by [SourceType] (json / jsonschema / graphql / typescript)
/// and map to one or more [TypeConfig]s describing where to find input files.
/// Targets are keyed by [TargetType] and describe where generated code lands
/// plus any language-specific [Arg]s.
///
/// Used transparently by [Quicktype.initialize]; direct interaction is only
/// needed for testing or advanced callers.
///
/// ```dart
/// final config = Config.initialize('quicktype.json');
/// for (final entry in config.targets.entries) { ... }
/// ```
class Config {
  // Default constants
  static const String _defaultModelPath = 'models/';
  static const String _defaultConfigFile = 'quicktype.json';
  static const String _quicktypeExe = './tool/node_modules/.bin/quicktype';

  // Singleton instance
  static Config? _instance;

  // Path the singleton was loaded from — used to detect conflicting re-inits.
  static String? _instancePath;

  /// Input file declarations, keyed by format.
  late final Map<SourceType, Set<TypeConfig>> sources;

  /// Output file declarations, keyed by target language.
  late final Map<TargetType, Set<TypeConfig>> targets;

  /// The default config file name — `quicktype.json`.
  static String get defaultConfigFile => _defaultConfigFile;

  /// Relative path to the bundled quicktype executable. Only used when
  /// running from a dev checkout of quicktype_dart; consumers installed
  /// from pub.dev should have `quicktype` on PATH.
  static String get quicktypeExe => _quicktypeExe;

  /// Fetches the underlying quicktype CLI's version string. Returns
  /// `'unknown'` if the executable isn't runnable.
  static Future<String> get quicktypeVersion async {
    try {
      final result = await Process.run(quicktypeExe, ['--version']);
      return result.stdout.toString().split('\n').first.trim();
    } catch (e) {
      Log.warning("Unable to retrieve quicktype version: $e");
      return 'unknown';
    }
  }

  /// Create or retrieve the `Config` singleton.
  ///
  /// Loads from [filePath] if it exists, otherwise falls back to defaults.
  /// If a second call passes a different [filePath] than the one that built
  /// the cached instance, throws [ConfigException] — call [Config.reset]
  /// first to reload from a new path.
  factory Config.initialize([String filePath = _defaultConfigFile]) {
    if (_instance != null) {
      if (_instancePath != null && _instancePath != filePath) {
        throw ConfigException(
          'Config already initialized from "$_instancePath"; refusing to '
          'silently ignore new path "$filePath". Call Config.reset() first.',
        );
      }
      return _instance!;
    }

    _instancePath = filePath;
    final configFile = File(filePath);
    if (configFile.existsSync()) {
      try {
        return _instance = Config._fromFile(configFile);
      } catch (e) {
        Log.info('Failed to load config file "$filePath". Using defaults: $e');
        return _instance = Config._default();
      }
    } else {
      Log.info('Config file "$filePath" not found. Loading defaults...');
      return _instance = Config._default();
    }
  }

  /// Clears the cached singleton so a subsequent [Config.initialize] call
  /// can load a fresh configuration. Primarily for tests and runtime reload.
  static void reset() {
    _instance = null;
    _instancePath = null;
  }

  /// Build default configuration
  Config._default() {
    // Ensure default model directory exists
    final modelDir = Directory(_defaultModelPath);
    if (!modelDir.existsSync()) {
      modelDir.createSync(recursive: true);
      Log.info('Created default models directory at: ${modelDir.path}');
    }

    this.sources = _defaultSources(modelDir.path);
    this.targets = _defaultTargets();
  }

  /// Generates default source configurations
  static Map<SourceType, Set<TypeConfig>> _defaultSources(String modelPath) {
    return {
      for (var source in SourceType.values)
        source: {
          TypeConfig(
            path: modelPath,
            type: source,
          )
        }
    };
  }

  /// Generates default target configurations
  static Map<TargetType, Set<TypeConfig>> _defaultTargets() {
    final targets = <TargetType, Set<TypeConfig>>{};

    for (var target in TargetType.values) {
      final configs = <TypeConfig>{};
      if (target.defaultPath != null) {
        try {
          final targetFiles = Glob(target.defaultPath!).listSync();
          for (final entity in targetFiles) {
            configs.add(TypeConfig(
              path: entity.path,
              type: target,
            ));
          }
        } catch (e) {
          Log.warning('Could not detect files for ${target.name}: $e');
        }
      }
      targets[target] = configs;
    }

    return targets;
  }

  /// Construct configuration from a file (JSON or YAML)
  Config._fromFile(File configFile) {
    try {
      final content = configFile.readAsStringSync();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        throw ConfigException(
          'Config root must be a JSON object, got ${decoded.runtimeType} '
          'in "${configFile.path}".',
        );
      }
      this.sources = _parseSources(decoded['sources']);
      this.targets = _parseTargets(decoded['targets']);
    } on ConfigException {
      rethrow;
    } catch (e) {
      throw ConfigException('Failed to parse configuration file', e);
    }
  }

  /// Parse source configurations from Map
  Map<SourceType, Set<TypeConfig>> _parseSources(dynamic sourcesMap) {
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

  /// Parse target configurations from Map
  Map<TargetType, Set<TypeConfig>> _parseTargets(dynamic targetsMap) {
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

  /// Parse configurations for a given type (source or target)
  Map<T, Set<TypeConfig>> _parseTypeConfigs<T extends TypeEnum>(
    Map<String, dynamic> configMap,
    List<T> validTypes,
    String section,
  ) {
    final result = <T, Set<TypeConfig>>{};

    for (final entry in configMap.entries) {
      final key = entry.key.toLowerCase();

      T? matchingType;
      for (T validType in validTypes) {
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
      final configs = rawList.map((config) {
        return TypeConfig.fromJson(matchingType!, config);
      }).toSet();

      result[matchingType] = configs;
    }

    return result;
  }
}
