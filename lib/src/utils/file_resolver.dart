library;

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

import '../config.dart';
import '../models/type.dart';
import 'logging.dart';

/// Glob-based file discovery and source→target path rewriting.
///
/// Used by the `quicktype.json`-driven flow ([Quicktype.buildCommandsFromConfig])
/// to expand each configured source glob into concrete paths and map each
/// source file onto its output path for the given target language.
class FileResolver {
  /// Returns every file under [pattern] whose extension is in [extensions].
  ///
  /// [pattern] may be a literal path or any `package:glob` pattern (e.g.
  /// `lib/**/models/*.json`). When [pattern] has no extension a trailing
  /// `/*` is appended so the glob matches files directly inside the
  /// directory. When [pattern] carries an explicit extension, that
  /// extension must appear in [extensions] or a [ConfigException] is
  /// thrown.
  ///
  /// Returns absolute paths; duplicates are collapsed into a set.
  static Set<String> getFiles(String pattern, Set<String> extensions) {
    final matches = <String>{};
    final validExtensions = extensions;
    try {
      pattern = path.canonicalize(pattern);
      final String patternExtension = path.extension(pattern);
      String searchExtensions = validExtensions.length > 1
          ? validExtensions.toSet().toString()
          : validExtensions.first;

      // Sanity check the extensions list, and finalize which extensions to search.
      if (patternExtension.isEmpty) {
        pattern = pattern.endsWith('*') ? pattern : '$pattern/*';
      } else {
        if (validExtensions.contains(patternExtension)) {
          searchExtensions = patternExtension;
        } else {
          throw ConfigException('Invalid extension: $patternExtension');
        }
      }

      // Build the list of matched files.
      Log.off('');
      Log.off('Searching for $searchExtensions');
      Log.off(pattern);
      try {
        final glob = Glob('$pattern$searchExtensions');
        final files = glob.listSync().toList();
        for (final file in files) {
          if (file is File) {
            final fileExtension = path.extension(file.path, 2);
            if (searchExtensions.contains(fileExtension)) {
              matches.add(file.absolute.path);
            }
          }
        }
      } catch (e) {
        Log.severe('Error: $e');
      }

      if (matches.isNotEmpty) {
        var counter = 0;
        for (final file in matches) {
          counter++;
          Log.info('     ($counter/${matches.length}): $file');
        }
      } else {
        Log.info('     (0/0): No files found');
      }
      return matches;
    } catch (e) {
      throw ConfigException('Error resolving files for pattern: $pattern', e);
    }
  }

  /// Maps [sourcePath] onto an output file for [targetType] under
  /// [targetConfig]'s `path`.
  ///
  /// If [targetConfig.path] looks like a file (has an extension), only its
  /// parent directory is used; otherwise the whole path is treated as a
  /// directory. The output filename is the source basename plus the
  /// target language's primary extension (e.g. `user.json` →
  /// `<dir>/user.dart`).
  static String resolveTargetPath(
    String sourcePath,
    TargetType targetType,
    TypeConfig targetConfig,
  ) {
    final sourceName = path.basenameWithoutExtension(sourcePath);

    final targetPath = targetConfig.path;
    final targetPathExt = path.extension(targetPath);

    final targetExt =
        targetType.extensions.first; // Default to the first extension value.
    final targetName = '$sourceName$targetExt';

    // Make sure you're referencing a folder.
    var parentFolder = targetPath;
    if (targetPathExt.isNotEmpty) {
      parentFolder = path.dirname(targetPath);
    }
    return path.join(parentFolder, targetName);
  }
}
