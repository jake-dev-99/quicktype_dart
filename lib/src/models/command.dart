import 'package:build/build.dart';
import 'package:path/path.dart' as Path;

import '../utils/type_infer.dart';
import 'args.dart';
import 'type.dart';

/// A single quicktype invocation — one source file, one target file, plus any
/// extra typed [Arg]s (language-specific flags, options, etc).
///
/// The command builds `--src/--src-lang/--lang/--out` itself; callers supply
/// the rest via [args] using typed arg classes like `DartArgs.useFreezed`.
class QuicktypeCommand {
  /// Source file path.
  final String sourcePath;

  /// `--src-lang` value (e.g. `'json'`).
  final String sourceArg;

  /// Output file path.
  final String targetPath;

  /// `--lang` value (e.g. `'dart'`).
  final String targetArg;

  /// Extra typed arguments — e.g. `[DartArgs.useFreezed..value = true]`.
  final Iterable<Arg> args;

  QuicktypeCommand({
    required this.sourcePath,
    required this.sourceArg,
    required this.targetPath,
    required this.targetArg,
    this.args = const [],
  });

  /// Convenience builder: infer source and target types from each file's
  /// extension (honouring multi-dot extensions like `.schema.json`).
  /// Throws [ArgumentError] if either side has an unsupported extension.
  static QuicktypeCommand createCommandForFiles({
    required AssetId sourceFile,
    required AssetId targetFile,
    Iterable<Arg> args = const [],
  }) {
    final sourceType =
        inferLangType<SourceType>(SourceType.values, sourceFile.path) ??
            (throw ArgumentError(
                'Unsupported source file type: ${sourceFile.path}'));

    final targetType =
        inferLangType<TargetType>(TargetType.values, targetFile.path) ??
            (throw ArgumentError(
                'Unsupported target file type: ${targetFile.path}'));

    return QuicktypeCommand(
      sourcePath: sourceFile.path,
      sourceArg: sourceType.argName,
      targetPath: targetFile.path,
      targetArg: targetType.argName,
      args: args,
    );
  }

  /// Full command line for display/debugging.
  String get parsed => 'quicktype ${argv.join(' ')}';

  /// Argv list suitable for `Process.run`.
  List<String> get argv => _toArgv();

  List<String> _toArgv() {
    final out = <String>[
      '--src', Path.canonicalize(sourcePath),
      '--src-lang', sourceArg,
      '--lang', targetArg,
      '--out', Path.canonicalize(targetPath),
    ];
    for (final arg in args) {
      out.addAll(arg.argv());
    }
    return out;
  }
}
