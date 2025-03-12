import 'package:build/build.dart';
import 'package:path/path.dart' as Path;

import 'type.dart';

/// Represents a single quicktype command with all its arguments
///
/// Encapsulates all the information needed to run a single quicktype
/// code generation command.
class QuicktypeCommand {
  /// Additional args passed through to Quicktype
  final List<String>? mainArgs;

  /// The source File path
  final String sourcePath;

  /// Source Type (as Quicktype Arg)
  final String sourceArg;

  /// Target file or directory path
  final String targetPath;

  /// The target Type (Dart, TypeScript, etc.)
  final String targetArg;

  /// Additional target args passed through to Quicktype
  final List<String>? targetArgs;

  /// Creates a new quicktype command
  ///
  /// [sourcePath] The source format type
  /// [sourceArg] Path to source file(s)
  /// [targetPath] Path for generated target
  /// [targetArg] The target Type type
  QuicktypeCommand({
    required this.mainArgs,
    required this.sourcePath,
    required this.sourceArg,
    required this.targetPath,
    required this.targetArg,
    required this.targetArgs,
  });

  /// Creates a quicktype command for the given file
  static QuicktypeCommand createCommandForFiles({
    required AssetId sourceFile,
    required AssetId targetFile,
  }) {
    // Determine source type based on extension
    final sourceType = SourceType.values.firstWhere(
      (t) => t.extensions.contains(Path.extension(targetFile.path)),
      orElse: () => throw ArgumentError(
          'Unsupported target file type: ${targetFile.path}'),
    );

    // Determine source type based on extension
    final targetType = TargetType.values.firstWhere(
      (t) => t.extensions.contains(Path.extension(targetFile.path)),
      orElse: () => throw ArgumentError(
          'Unsupported target file type: ${targetFile.path}'),
    );

    // Create command
    return QuicktypeCommand(
      mainArgs: [],
      sourcePath: sourceFile.path,
      sourceArg: sourceType.argName,
      targetPath: targetFile.path,
      targetArg: targetType.argName,
      targetArgs: [],
    );
  }

  /// The full command line string
  ///
  /// @return The full command line string
  get parsed => 'quicktype ${_toArgs().join(' ')}';
  get args => _toArgs();

  /// Converts this command to a list of command line arguments
  ///
  /// @return A list of formatted command line arguments
  List<String> _toArgs() {
    var result = <String>[];

    // Core arguments
    result.addAll(mainArgs ?? []);
    result.addAll(['--src', Path.canonicalize(sourcePath)]);
    result.addAll(['--src-lang', sourceArg]);
    result.addAll(['--lang', targetArg]);
    result.addAll(['--out', Path.canonicalize(targetPath)]);
    result.addAll(targetArgs ?? []);

    result = _escapeArgs(result);
    return result;
  }

  /// Escapes a command line argument if needed
  ///
  /// [arg The argument to escape
  /// @return The escaped argument
  List<String> _escapeArgs(List<String> args) {
    for (String arg in args) {
      if (arg.contains(' ') || arg.contains('"')) {
        arg = '"${arg.replaceAll('"', '\\"')}"';
      }
    }
    return args;
  }
}
