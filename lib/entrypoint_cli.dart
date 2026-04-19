library;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'src/config.dart';
import 'src/quicktype.dart';
import 'src/utils/logging.dart';
import 'src/version.dart';


/// Entry point for the `quicktype_dart` CLI.
///
/// Wired up from [bin/quicktype_dart.dart] — run it with:
///
/// ```bash
/// dart run quicktype_dart            # uses ./quicktype.json
/// dart run quicktype_dart -c foo.json
/// dart run quicktype_dart -- --help  # pass-through to the quicktype CLI
/// ```
class QuicktypeCLI {
  /// Runs the CLI with [args] and returns the exit code (0 on success).
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
      Log.off('Error: $e');
      Log.off('Stack trace: $stackTrace');
      return 1;
    }
  }

  /// Loads [configPath] into a [Quicktype] singleton, expands into commands,
  /// and executes them. Returns exit code 0 on full success, 1 if any
  /// command failed.
  static Future<int> _generateFromConfig(configPath) async {
    Log.off('Running quicktype with config: $configPath');

    final quicktype = Quicktype.initialize();
    final commands = await quicktype.buildCommandsFromConfig();
    final results = await quicktype.executeAll(commands);

    final successCount = results.where((r) => r.success).length;
    Log.off('Generated $successCount/${results.length} files successfully');

    // Print any errors
    final failures = results.where((r) => !r.success).toList();
    if (failures.isNotEmpty) {
      Log.off('\nErrors:');
      for (final f in failures) {
        Log.off('  - ${f.sourcePath} → ${f.targetPath}: ${f.errorMessage}');
      }
      return 1;
    }

    return 0;
  }

  /// Print CLI usage information
  static void _printUsage() {
    Log.off('''
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

For more details: https://github.com/jake-dev-99/quicktype_dart
''');
  }

  /// Print version information
  static void _printVersion() {
    Log.off('Quicktype Dart v$packageVersion');

    try {
      final result = Process.runSync('quicktype', ['--version']);
      if (result.exitCode == 0) {
        Log.off('Native quicktype: ${result.stdout.toString().trim()}');
      } else {
        Log.off('Native quicktype: not available');
      }
    } catch (_) {
      Log.off('Native quicktype: not installed');
    }
  }
}
