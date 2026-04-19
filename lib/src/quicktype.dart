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

/// Thrown when a quicktype subprocess call fails or its output can't be
/// consumed. Carries the failing command and exit code when available.
class QuicktypeException implements Exception {
  /// Human-readable description of the failure.
  final String message;

  /// The quicktype command line that triggered the failure, if captured.
  final String? command;

  /// Subprocess exit code, if the command actually ran.
  final int? exitCode;

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

/// Singleton orchestrator that pairs a loaded [Config] with command
/// execution. Used by the CLI and programmatic callers that want the
/// `quicktype.json`-driven flow.
///
/// For one-shot in-memory conversions, use [QuicktypeDart.generate]
/// instead — it skips the config layer entirely.
///
/// ```dart
/// final qt = Quicktype.initialize(); // loads quicktype.json, or defaults
/// final commands = await qt.buildCommandsFromConfig();
/// final results = await qt.executeAll(commands);
/// ```
class Quicktype {
  static Quicktype? _instance;

  /// The [Config] that was loaded when the singleton was created.
  late Config config;

  /// Creates (or returns) the singleton, optionally loading config from
  /// [configPath]. First call wins — use [Quicktype.reset] to reload.
  factory Quicktype.initialize([String? configPath]) {
    _instance ??= Quicktype._initialize(configPath);
    return _instance!;
  }

  /// Clears the cached singleton so a subsequent [Quicktype.initialize] call
  /// can load a fresh [Config]. Also resets the underlying [Config] singleton.
  static void reset() {
    _instance = null;
    Config.reset();
  }

  Quicktype._initialize([String? configPath]) {
    config = configPath == null
        ? Config.initialize()
        : Config.initialize(configPath);
  }

  /// Expands [config]'s sources × targets into concrete [QuicktypeCommand]s.
  ///
  /// For each declared source file (after glob expansion) × each declared
  /// target language/path, yields one command. Does not execute them —
  /// pass the result to [executeAll] or [execute] to generate output.
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

            results.add(QuicktypeCommand(
              sourcePath: sourceFile,
              targetPath: targetFile,
              sourceArg: sourceType.argName,
              targetArg: targetType.argName,
              args: targetConfig.args,
            ));
          }
        }
      }
    }
    return results;
  }

  /// Runs [commands] serially via [execute], aggregating results.
  Future<List<QuicktypeResult>> executeAll(
      List<QuicktypeCommand> commands) async {
    final results = <QuicktypeResult>[];
    Log.off('');
    Log.off('========================================');

    for (QuicktypeCommand command in commands) {
      final result = await execute(command);
      results.add(result);
    }
    return results;
  }

  /// Runs a single [command] via `Process.run`. Creates the target
  /// directory if needed and returns a [QuicktypeResult] describing the
  /// outcome (success or failure).
  Future<QuicktypeResult> execute(QuicktypeCommand command) async {
    final sourcePath = Path.absolute(command.sourcePath);
    final targetPath = Path.absolute(command.targetPath);
    Log.off('');
    Log.off('Generating $targetPath');

    try {
      final parentDir = Directory(Path.dirname(targetPath));
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      final result =
          await Process.run(_QUICKTIME_EXE, command.argv).catchError((e) {
        throw QuicktypeException('Failed to run quicktype',
            command: 'quicktype');
      });
      if (result.exitCode == 0) {
        if (result.stdout.toString().isNotEmpty) {
          Log.off('${result.stdout}');
        }
        Log.off('Done!');
      } else {
        Log.severe('Error: ${result.stderr}');
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
      Log.severe('Error: $e');
      for (String line in s.toString().split('\n')) {
        Log.severe('$line');
      }
      return QuicktypeResult.failure(
        sourcePath: sourcePath,
        targetPath: targetPath,
        errorMessage: e.toString(),
      );
    }
  }

  /// Passes [args] straight through to the `quicktype` on `PATH`, bypassing
  /// config and command construction. Used when the CLI is invoked with
  /// positional args beyond the known flags.
  static Future<int> executeNative(List<String> args) async {
    Log.off('');
    Log.off('Running native quicktype: ${args.join(' ')}');

    try {
      final result = await Process.run('quicktype', args);

      if (result.stdout.toString().isNotEmpty) {
        Log.off('Result: ${result.stdout}');
      }

      if (result.stderr.toString().isNotEmpty) {
        Log.off('Result: ${result.stderr}');
      }

      return result.exitCode;
    } catch (e) {
      if (e is ProcessException && e.executable == 'quicktype') {
        Log.off('');
        Log.off('Error: Native quicktype not found');
        Log.off('Install with: npm install -g quicktype');
      } else {
        Log.off('Error: $e');
      }
      return 1;
    }
  }
}
