import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';

import 'src/config.dart';
import 'src/quicktype.dart';
import 'src/utils/logging.dart';


// TODO: Nest targets under sources in config file

/// CLI entrypoint for quicktype code generation
class QuicktypeCLI {
  /// Runs the CLI with the given arguments
  static Future<int> run(List<String> args) async {
    final parser = ArgParser()
      ..addOption('config',
          abbr: 'c',
          defaultsTo: Config.defaultConfigFile,
          help: 'Path to configuration file')
      ..addFlag('help',
          abbr: 'h', negatable: false, help: 'Display usage information')
      ..addFlag('version',
          abbr: 'v', negatable: false, help: 'Display version information');

    try {
      final options = parser.parse(args);

      // Handle help request
      if (options['help']) {
        _printUsage();
        return 0;
      }

      // Handle version request
      if (options['version']) {
        _printVersion();
        return 0;
      }

      // If any additional arguments provided, run against native quicktype
      if (options.rest.isNotEmpty) {
        return await Quicktype.executeNative(options.rest);
      }

      // Run with specified config
      final configPath = options['config'];
      return await _generateFromConfig(configPath);
    } catch (e, stackTrace) {
      Log.OFF('Error: $e');
      Log.OFF('Stack trace: $stackTrace');
      return 1;
    }
  }

  /// Generate code using a config file
  static Future<int> _generateFromConfig(configPath) async {
    Log.OFF('Running quicktype with config: $configPath');

    final quicktype = Quicktype.initialize();
    final commands = await quicktype.buildCommandsFromConfig();
    final results = await quicktype.executeAll(commands);

    final successCount = results.where((r) => r.success).length;
    Log.OFF('Generated $successCount/${results.length} files successfully');

    // Print any errors
    final failures = results.where((r) => !r.success).toList();
    if (failures.isNotEmpty) {
      Log.OFF('\nErrors:');
      for (final f in failures) {
        Log.OFF('  - ${f.sourcePath} → ${f.targetPath}: ${f.errorMessage}');
      }
      return 1;
    }

    return 0;
  }

  /// Print CLI usage information
  static void _printUsage() {
    Log.OFF('''
Quicktype Dart - Generate types from schemas

Usage:
  quicktype [options]

Options:
  --config, -c FILE   Config file path (default: quicktype.json)
  --help, -h          Show help
  --version, -v       Show version

Examples:
  quicktype                  Generate using quicktype.json
  quicktype -c custom.json   Generate using custom.json

For more details: https://github.com/yourusername/quicktype_dart
''');
  }

  /// Print version information
  static void _printVersion() {
    Log.OFF('Quicktype Dart v1.0.0');

    try {
      final result = Process.runSync('quicktype', ['--version']);
      if (result.exitCode == 0) {
        Log.OFF('Native quicktype: ${result.stdout.toString().trim()}');
      } else {
        Log.OFF('Native quicktype: not available');
      }
    } catch (_) {
      Log.OFF('Native quicktype: not installed');
    }
  }
}
