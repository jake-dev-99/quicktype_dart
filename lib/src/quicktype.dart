library;

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'config.dart';
import 'internal/quicktype_process.dart';
import 'models/command.dart';
import 'models/result.dart';
import 'file_resolver.dart';
import 'logging.dart';

/// Thrown when a quicktype subprocess call fails or its output can't be
/// consumed. Carries the failing command and exit code when available,
/// plus the underlying [cause] and its [stackTrace] when wrapping another
/// error so callers can diagnose without losing context.
@immutable
class QuicktypeException implements Exception {
  /// Creates a subprocess failure with a human-readable [message] plus
  /// optional diagnostic context.
  const QuicktypeException(
    this.message, {
    this.command,
    this.exitCode,
    this.cause,
    this.stackTrace,
  });

  /// Human-readable description of the failure.
  final String message;

  /// The quicktype command line that triggered the failure, if captured.
  final String? command;

  /// Subprocess exit code, if the command actually ran.
  final int? exitCode;

  /// The underlying error this exception wraps, if any.
  final Object? cause;

  /// The stack trace of [cause], if captured.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('QuicktypeException: $message');
    if (command != null) {
      buffer.write('\nCommand: $command');
    }
    if (exitCode != null) {
      buffer.write('\nExit code: $exitCode');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Pairs a [Config] with command execution. Used by the CLI and
/// programmatic callers that want the `quicktype.json`-driven flow.
///
/// One instance per config. Constructing multiple `Quicktype`s with
/// different configs in the same process is supported — they share no
/// mutable state.
///
/// For one-shot in-memory conversions, use `QuicktypeDart.generate`
/// instead — it skips the config layer entirely.
///
/// ```dart
/// final qt = Quicktype(Config.loadOrDefaults('quicktype.json'));
/// final commands = await qt.buildCommandsFromConfig();
/// final results = await qt.executeAll(commands);
/// ```
class Quicktype {
  /// Creates a new orchestrator bound to [config].
  Quicktype(this.config);

  /// The [Config] this orchestrator was constructed with.
  final Config config;

  /// Expands [config]'s sources × targets into concrete [QuicktypeCommand]s.
  ///
  /// For each declared source file (after glob expansion) × each declared
  /// target language/path, yields one command. Does not execute them —
  /// pass the result to [executeAll] or [execute] to generate output.
  Future<List<QuicktypeCommand>> buildCommandsFromConfig() async {
    final results = <QuicktypeCommand>[];

    for (final source in config.sources.entries) {
      final sourceType = source.key;
      final sourcePaths = source.value;

      final sourceFiles = sourcePaths
          .expand((typeConfig) =>
              FileResolver.getFiles(typeConfig.path, sourceType.extensions))
          .toSet();

      for (final sourceFile in sourceFiles) {
        for (final target in config.targets.entries) {
          final targetType = target.key;
          final targetConfigs = target.value;

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
              rendererOptions: targetConfig.rendererOptions,
            ));
          }
        }
      }
    }
    return results;
  }

  /// Runs [commands] serially via [execute], aggregating results.
  Future<List<QuicktypeResult>> executeAll(
    List<QuicktypeCommand> commands,
  ) async {
    final results = <QuicktypeResult>[];
    for (final command in commands) {
      final result = await execute(command);
      results.add(result);
    }
    return results;
  }

  /// Runs a single [command] via `Process.run`. Creates the target
  /// directory if needed and returns a [QuicktypeResult] describing the
  /// outcome (success or failure).
  Future<QuicktypeResult> execute(QuicktypeCommand command) async {
    final sourcePath = path.absolute(command.sourcePath);
    final targetPath = path.absolute(command.targetPath);
    Log.info('Generating $targetPath');

    try {
      final parentDir = Directory(path.dirname(targetPath));
      if (!parentDir.existsSync()) parentDir.createSync(recursive: true);

      final result = await runQuicktypeProcess(command.argv);

      final stdoutStr = (result.stdout as String).trimRight();
      final stderrStr = (result.stderr as String).trimRight();

      if (result.exitCode != 0) {
        if (stderrStr.isNotEmpty) Log.warning(stderrStr);
        return QuicktypeResult.failure(
          sourcePath: sourcePath,
          targetPath: targetPath,
          errorMessage: stderrStr.isNotEmpty
              ? stderrStr
              : 'quicktype exited with code ${result.exitCode}',
          stdout: stdoutStr.isEmpty ? null : stdoutStr,
          stderr: stderrStr.isEmpty ? null : stderrStr,
        );
      }

      if (stdoutStr.isNotEmpty) Log.info(stdoutStr);
      if (stderrStr.isNotEmpty) Log.warning(stderrStr);
      return QuicktypeResult.success(
        sourcePath: sourcePath,
        targetPath: targetPath,
        stdout: stdoutStr.isEmpty ? null : stdoutStr,
        stderr: stderrStr.isEmpty ? null : stderrStr,
      );
    } catch (e, s) {
      Log.severe('Error: $e\n$s');
      return QuicktypeResult.failure(
        sourcePath: sourcePath,
        targetPath: targetPath,
        errorMessage: e.toString(),
      );
    }
  }

  /// Passes [args] straight through to the resolved `quicktype` CLI
  /// (bundled first, then PATH), bypassing config and command construction.
  /// Used when the CLI is invoked with positional args beyond the known
  /// flags.
  static Future<int> executeNative(List<String> args) async {
    Log.info('Running quicktype ${args.join(' ')}');
    try {
      final result = await runQuicktypeProcess(args);
      final stdoutStr = (result.stdout as String).trimRight();
      final stderrStr = (result.stderr as String).trimRight();
      if (stdoutStr.isNotEmpty) Log.info(stdoutStr);
      if (stderrStr.isNotEmpty) Log.warning(stderrStr);
      return result.exitCode;
    } on QuicktypeException catch (e) {
      Log.severe(e.toString());
      return 1;
    }
  }
}
