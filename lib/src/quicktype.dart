library quicktype;

import 'dart:io';
import 'package:path/path.dart' as Path;
import 'utils/file_resolver.dart';
import 'utils/logging.dart';

import 'config.dart';
import 'models/command.dart';
import 'models/result.dart';

// TODO: "Consolidate" option - loads all files into memory, then outputs to models.py, etc
// TODO: Normalize Source and Target name patterns
// TODO: Implement all extra args (main and per-Type)
const String _QUICKTIME_EXE = './tool/node_modules/.bin/quicktype';

/// Exception thrown when quicktype execution fails
class QuicktypeException implements Exception {
  /// The error message
  final String message;

  /// The underlying command that failed (if available)
  final String? command;

  /// Exit code from the process (if available)
  final int? exitCode;

  /// Creates a new quicktype exception
  QuicktypeException(this.message, {this.command, this.exitCode});

  @override
  String toString() {
    final buffer = StringBuffer('QuicktypeException: $message');
    if (command != null) {
      buffer.write('\nCommand: $command');
    }
    if (exitCode != null) {
      buffer.write('\nExit code: $exitCode');
    }
    return buffer.toString();
  }
}

/// A combined class that handles both quicktype configuration and execution
class Quicktype {
  /// Singleton instance
  static Quicktype? _instance;

  /// Current configuration
  late Config config;

  /// Creates the singleton instance
  factory Quicktype.initialize([String? configPath]) {
    _instance ??= Quicktype._initialize();
    return _instance!;
  }

  /// Initializes with a configuration file
  ///
  /// @param configPath Path to the configuration file (JSON or YAML)
  /// @param verbose Whether to enable verbose logging
  /// @param executablePath Optional path to the quicktype executable
  Quicktype._initialize([String? configPath]) {
    config = configPath == null
        ? Config.initialize()
        : Config.initialize(configPath);
  }

  /// Executes all commands defined in the configuration
  ///
  /// @return Future with the results of all operations
  Future<List<QuicktypeCommand>> buildCommandsFromConfig() async {
    final results = <QuicktypeCommand>[];

    // Loop each Source Type
    for (final source in config.sources.entries) {
      final sourceType = source.key;
      final sourcePaths = source.value;

      // Retrieve all matched Source Type files
      Set<String> sourceFiles = sourcePaths
          .expand((typeConfig) =>
              FileResolver.getFiles(typeConfig.path, sourceType.extensions))
          .toSet();

      // Generate all targets for each source file found
      for (final sourceFile in sourceFiles) {
        for (final target in config.targets.entries) {
          final targetType = target.key;
          final targetConfigs = target.value;

          // Loop all target configs for the current target type
          for (final targetConfig in targetConfigs) {
            final targetFile = FileResolver.resolveTargetPath(
              sourceFile,
              targetType,
              targetConfig,
            );

            // Finally add a command for every Source and Target config
            results.add(QuicktypeCommand(
              mainArgs: [],
              sourcePath: sourceFile,
              targetPath: targetFile,
              sourceArg: sourceType.argName,
              targetArg: targetType.argName,
              targetArgs: [],
            ));
          }
        }
      }
    }
    return results;
  }

  /// Executes all commands defined in the configuration
  ///
  /// @return Future with the results of all operations
  Future<List<QuicktypeResult>> executeAll(
      List<QuicktypeCommand> commands) async {
    final results = <QuicktypeResult>[];
    Log.OFF('');
    Log.OFF('========================================');

    for (QuicktypeCommand command in commands) {
      final result = await execute(command);
      results.add(result);
    }
    return results;
  }

  /// Executes a quicktype command
  ///
  /// @param command The command to execute
  /// @return Execution result
  Future<QuicktypeResult> execute(QuicktypeCommand command) async {
    final sourcePath = Path.absolute(command.sourcePath);
    final targetPath = Path.absolute(command.targetPath);
    Log.OFF('');
    Log.OFF('Generating $targetPath');

    try {
      final parentDir = Directory(Path.dirname(targetPath));
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      final result =
          await Process.run(_QUICKTIME_EXE, command.args).catchError((e) {
        throw QuicktypeException('Failed to run quicktype',
            command: 'quicktype');
      });
      if (result.exitCode == 0) {
        if (result.stdout.toString().isNotEmpty) {
          Log.OFF('${result.stdout}');
        }
        Log.OFF('Done!');
      } else {
        Log.SEVERE('Error: ${result.stderr}');
        return QuicktypeResult.failure(
          sourcePath: sourcePath,
          targetPath: targetPath,
          errorMessage: result.stderr.toString(),
        );
      }
      return QuicktypeResult.success(
        sourcePath: sourcePath,
        targetPath: targetPath,
      );
    } catch (e, s) {
      Log.SEVERE('Error: $e');
      for (String line in s.toString().split('\n')) {
        Log.SEVERE('$line');
      }
      return QuicktypeResult.failure(
        sourcePath: sourcePath,
        targetPath: targetPath,
        errorMessage: e.toString(),
      );
    }
  }

  /// Run native quicktype CLI
  static Future<int> executeNative(List<String> args) async {
    Log.OFF('');
    Log.OFF('Running native quicktype: ${args.join(' ')}');

    try {
      final result = await Process.run('quicktype', args);

      if (result.stdout.toString().isNotEmpty) {
        Log.OFF('Result: ${result.stdout}');
      }

      if (result.stderr.toString().isNotEmpty) {
        Log.OFF('Result: ${result.stderr}');
      }

      return result.exitCode;
    } catch (e) {
      if (e is ProcessException && e.executable == 'quicktype') {
        Log.OFF('');
        Log.OFF('Error: Native quicktype not found');
        Log.OFF('Install with: npm install -g quicktype');
      } else {
        Log.OFF('Error: $e');
      }
      return 1;
    }
  }
}
