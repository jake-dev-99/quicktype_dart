import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../internal/argv.dart';
import '../utils/type_infer.dart';
import 'type.dart';

/// A single quicktype invocation — one source file, one target file, plus any
/// extra renderer options (language-specific flags).
///
/// The command builds `--src/--src-lang/--lang/--out` itself; callers supply
/// the rest via [rendererOptions] — a `Map<String, String>` matching
/// quicktype-core's `rendererOptions` shape. The typed
/// `*RendererOptions` classes (e.g. `DartRendererOptions`) expose
/// `toRendererOptions()` for converting their named parameters into this
/// map.
@immutable
class QuicktypeCommand {
  /// Source file path.
  final String sourcePath;

  /// `--src-lang` value (e.g. `'json'`).
  final String sourceArg;

  /// Output file path.
  final String targetPath;

  /// `--lang` value (e.g. `'dart'`).
  final String targetArg;

  /// Renderer options applied to this invocation. Each entry becomes
  /// `--key value` on the argv list; bool entries (`'true'`/`'false'`)
  /// collapse to `--key` / `--no-key` to match quicktype's CLI conventions.
  final Map<String, String> rendererOptions;

  /// Creates a command describing a single quicktype invocation.
  const QuicktypeCommand({
    required this.sourcePath,
    required this.sourceArg,
    required this.targetPath,
    required this.targetArg,
    this.rendererOptions = const {},
  });

  /// Convenience builder: infer source and target types from each file's
  /// extension (honouring multi-dot extensions like `.schema.json`).
  /// Throws [ArgumentError] if either side has an unsupported extension.
  static QuicktypeCommand createCommandForFiles({
    required AssetId sourceFile,
    required AssetId targetFile,
    Map<String, String> rendererOptions = const {},
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
      rendererOptions: rendererOptions,
    );
  }

  /// Full command line for display/debugging.
  String get parsed => 'quicktype ${argv.join(' ')}';

  /// Argv list suitable for `Process.run`.
  List<String> get argv => _toArgv();

  List<String> _toArgv() => <String>[
        '--src',
        path.canonicalize(sourcePath),
        '--src-lang',
        sourceArg,
        '--lang',
        targetArg,
        '--out',
        path.canonicalize(targetPath),
        ...rendererOptionsToArgv(rendererOptions),
      ];
}
