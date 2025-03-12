import 'package:build/build.dart';
import 'src/models/type.dart';
import 'src/models/command.dart';
import 'src/quicktype.dart';
import 'package:path/path.dart' as Path;

/// Builder implementation for generating code with quicktype
class QuicktypeBuilder implements Builder {
  /// Configuration for this builder
  final BuilderOptions options;

  /// Creates a new quicktype builder
  QuicktypeBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    // Get all source file extensions
    final sourceExtensions = SourceType.values
        .expand((lang) => lang.extensions)
        .map((ext) => '.$ext')
        .toSet();

    // Get all target file extensions
    final targetExtensions = TargetType.values
        .expand((lang) => lang.extensions)
        .map((ext) => '.$ext')
        .toSet() // Remove any potential duplicates
        .toList();

    // Create a map where each source extension maps to all target extensions
    return {
      for (final sourceExt in sourceExtensions) sourceExt: targetExtensions
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final quicktype = Quicktype.initialize();

    // Get the source file and path
    final sourceFile = buildStep.inputId;
    final sourcePath = Path.absolute(sourceFile.path);
    final sourceBaseName = Path.basenameWithoutExtension(sourcePath);

    List<QuicktypeCommand> commands = [];

    for (final target in quicktype.config.targets.entries) {
      TargetType targetType = target.key;
      String targetExtension = targetType.extensions.first;

      for (TypeConfig targetConfig in target.value) {
        String targetFile = '$sourceBaseName.$targetExtension';
        String targetPath = Path.join(targetConfig.path, targetFile);

        commands.add(QuicktypeCommand.createCommandForFiles(
          sourceFile: sourceFile,
          targetFile: AssetId(sourceFile.package, targetPath),
        ));
      }
    }

    try {
      // Execute conversion
      final results = await quicktype.executeAll(commands);
      for (final result in results) {
        if (result.success && result.targetContent != null) {
        } else {
          log.warning(
              'Failed to generate code for $sourcePath: ${result.errorMessage}');
        }
      }
    } catch (e, stackTrace) {
      log.severe('Error generating code for $sourcePath: $e', null, stackTrace);
    }
  }

  /// Creates a quicktype builder for the build_runner system
  Builder quicktypeBuilder(BuilderOptions options) => QuicktypeBuilder(options);
}
