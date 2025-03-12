import 'dart:io';

import 'package:path/path.dart' as Path;

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:quicktype_dart/src/models/type.dart';
import 'logging.dart';
import '../config.dart';

/// Handles file pattern matching and path resolution
class FileResolver {
  /// Finds all files matching a pattern
  ///
  /// Handles glob patterns and directory traversal
  ///
  /// @param pattern File pattern to match (e.g., "*.json" or "/path/to/file.json")
  /// @return List of matching file paths
  static Set<String> getFiles(String pattern, Set<String> extensions) {
    // Set to store the matched files (to avoid duplicates)
    final matches = <String>{};
    final validExtensions = extensions;
    try {
      pattern = Path.canonicalize(pattern);
      final String patternExtension = Path.extension(pattern);
      String searchExtensions = validExtensions.length > 1
          ? validExtensions.toSet().toString()
          : validExtensions.first;

      // Sanity check the extensions list, and finalize which extensions to search
      if (patternExtension.isEmpty) {
        pattern = pattern.endsWith('*') ? '$pattern' : '$pattern/*';
      } else {
        if (validExtensions.contains(patternExtension))
          searchExtensions = patternExtension;
        else
          throw ConfigException(
            'Invalid extension: ${patternExtension}',
          );
      }

      // Build the list of matched files
      Log.OFF('');
      Log.OFF('Searching for $searchExtensions');
      Log.OFF('$pattern');
      try {
        final glob = Glob('$pattern$searchExtensions');
        final files = glob.listSync().toList();
        for (final file in files) {
          if (file is File) {
            String fileExtension = Path.extension(file.path, 2);
            if (searchExtensions.contains(fileExtension)) {
              matches.add(file.absolute.path);
            }
          }
        }
      } catch (e) {
        Log.SEVERE("Error: $e");
      }

      if (matches.isNotEmpty) {
        int counter = 0;
        for (final file in matches) {
          counter++;
          Log.INFO("     ($counter/${matches.length}): $file");
        }
      } else {
        Log.INFO("     (0/0): No files found");
      }
      return matches;
    } catch (e) {
      throw ConfigException('Error resolving files for pattern: $pattern', e);
    }
  }

  /// Determines a target path based on source file and configuration
  ///
  /// @param sourcePath The source file path
  /// @param targetConfig The target configuration
  /// @param targetType The target Type type
  /// @return The resolved target path
  static String resolveTargetPath(
    String sourcePath,
    TargetType targetType,
    TypeConfig targetConfig,
  ) {
    final sourceName = Path.basenameWithoutExtension(sourcePath);

    final targetPath = targetConfig.path;
    final targetPathExt = Path.extension(targetPath);

    final targetExt =
        targetType.extensions.first; // Default to the first extension value
    final targetName = '$sourceName$targetExt';

    // Make sure you're referencing a folder
    String parentFolder = targetPath;
    if (targetPathExt.isNotEmpty) {
      parentFolder = Path.dirname(targetPath);
    }
    return Path.join(parentFolder, targetName);
  }
}
