import 'dart:convert';
import 'dart:io';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'models/type.dart';
import 'utils/logging.dart';

/// Exception to represent configuration errors
class ConfigException implements Exception {
  final String message;
  final Object? cause;

  const ConfigException(this.message, [this.cause]);

  @override
  String toString() => cause != null
      ? 'ConfigException: $message\nCaused by: $cause'
      : 'ConfigException: $message';
}

/// Configuration for quicktype processing
///
/// Supports both source and target configurations for code generation.
/// Optionally loads from a configuration file or falls back to default settings.
class Config {
  // Default constants
  static const String _defaultModelPath = 'models/';
  static const String _defaultConfigFile = 'quicktype.json';
  static const String _quicktypeExe = './tool/node_modules/.bin/quicktype';

  // Singleton instance
  static Config? _instance;

  // Configuration sources and targets
  late final Map<SourceType, Set<TypeConfig>> sources;
  late final Map<TargetType, Set<TypeConfig>> targets;

  // Package config getters
  static String get defaultConfigFile => _defaultConfigFile;
  static String get quicktypeExe => _quicktypeExe;

  /// Fetch quicktype version asynchronously
  static Future<String> get quicktypeVersion async {
    try {
      final result = await Process.run(quicktypeExe, ['--version']);
      return result.stdout.toString().split('\n').first.trim();
    } catch (e) {
      Log.WARNING("Unable to retrieve quicktype version: $e");
      return 'unknown';
    }
  }

  /// Create or retrieve the `Config` singleton instance
  ///
  /// Attempts to load from a file. If the file isn't found or invalid, falls back
  /// to default configuration.
  factory Config.initialize([String filePath = _defaultConfigFile]) {
    if (_instance != null) {
      return _instance!;
    }

    // Attempt to load config from file
    final configFile = File(filePath);
    if (configFile.existsSync()) {
      try {
        return _instance = Config._fromFile(configFile);
      } catch (e) {
        Log.INFO('Failed to load config file "$filePath". Using defaults: $e');
        return _instance = Config._default();
      }
    } else {
      Log.INFO('Config file "$filePath" not found. Loading defaults...');
      return _instance = Config._default();
    }
  }

  /// Build default configuration
  Config._default() {
    // Ensure default model directory exists
    final modelDir = Directory(_defaultModelPath);
    if (!modelDir.existsSync()) {
      modelDir.createSync(recursive: true);
      Log.INFO('Created default models directory at: ${modelDir.path}');
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
          Log.WARNING('Could not detect files for ${target.name}: $e');
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
      final map = jsonDecode(content) as Map<String, dynamic>;
      this.sources = _parseSources(map['sources']);
      this.targets = _parseTargets(map['targets']);
    } catch (e) {
      throw ConfigException('Failed to parse configuration file', e);
    }
  }

  /// Parse source configurations from Map
  Map<SourceType, Set<TypeConfig>> _parseSources(dynamic sourcesMap) {
    if (sourcesMap == null) {
      Log.WARNING('Sources missing in config file. Using default sources.');
      return _defaultSources(_defaultModelPath);
    }

    return _parseTypeConfigs<SourceType>(
      sourcesMap as Map<String, dynamic>,
      SourceType.values,
      'source',
    );
  }

  /// Parse target configurations from Map
  Map<TargetType, Set<TypeConfig>> _parseTargets(dynamic targetsMap) {
    if (targetsMap == null) {
      Log.WARNING('Targets missing in config file. Using default targets.');
      return _defaultTargets();
    }

    return _parseTypeConfigs<TargetType>(
      targetsMap as Map<String, dynamic>,
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
      final configs = (entry.value as List).map((config) {
        return TypeConfig.fromJson(matchingType!, config);
      }).toSet();

      result[matchingType!] = configs;
    }

    return result;
  }
}
