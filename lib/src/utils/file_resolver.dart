import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import '../models/type.dart';

/// Expands config-declared paths into concrete source-file lists, filtered
/// by the [TypeEnum.extensions] set of the declaring type.
///
/// Package-private. The Config/Quicktype orchestration layer is the only
/// caller; end users reach for `QuicktypeDart.generate` or the build_runner
/// builders instead.
class FileResolver {
  FileResolver._();

  /// Returns the set of absolute file paths under [pattern] whose extension
  /// is one of [extensions].
  ///
  /// [pattern] may be:
  ///   * A specific file whose extension is already in [extensions] — the
  ///     file is returned as-is if it exists.
  ///   * A directory — every immediate child with a matching extension
  ///     (via `{ext1,ext2}` brace expansion) is returned.
  ///   * A glob — passed through; matches filtered against [extensions].
  ///
  /// [extensions] entries include the leading dot (e.g. `.json`,
  /// `.schema.json`). At least one entry is required.
  ///
  /// Throws [ConfigException] if [extensions] is empty, if [pattern] has an
  /// extension outside [extensions], or if the glob is malformed.
  static Set<String> getFiles(String pattern, Set<String> extensions) {
    if (extensions.isEmpty) {
      throw ConfigException(
        'FileResolver.getFiles requires at least one extension; '
        'got an empty set for pattern "$pattern".',
      );
    }

    final matchedExt = _longestEndsWithMatch(pattern, extensions);
    final String globPattern;
    if (matchedExt != null) {
      globPattern = pattern;
    } else if (p.extension(pattern).isNotEmpty) {
      throw ConfigException(
        'Invalid extension "${p.extension(pattern)}" in pattern "$pattern". '
        'Allowed: ${extensions.join(", ")}.',
      );
    } else {
      final prefix = pattern.endsWith('*') ? pattern : '$pattern/*';
      final extAlt = extensions.length == 1
          ? extensions.first
          : '{${extensions.join(',')}}';
      globPattern = '$prefix$extAlt';
    }

    final matches = <String>{};
    try {
      for (final entity in Glob(globPattern).listSync()) {
        if (entity is! File) continue;
        if (_longestEndsWithMatch(entity.path, extensions) != null) {
          matches.add(entity.absolute.path);
        }
      }
    } on FormatException catch (e) {
      throw ConfigException(
        'Invalid glob pattern "$globPattern": ${e.message}',
        e,
      );
    }
    return matches;
  }

  /// Derives the on-disk output path for a generated artifact.
  ///
  /// The result directory is [TypeConfig.path] when it already points at a
  /// directory, or its parent when it points at a file. The file stem is
  /// taken from [sourcePath]; the extension from [TargetType.extensions].
  static String resolveTargetPath(
    String sourcePath,
    TargetType targetType,
    TypeConfig targetConfig,
  ) {
    final sourceName = p.basenameWithoutExtension(sourcePath);
    final targetExt = targetType.extensions.first;
    final targetName = '$sourceName$targetExt';

    final targetPath = targetConfig.path;
    final parent = p.extension(targetPath).isEmpty
        ? targetPath
        : p.dirname(targetPath);
    return p.join(parent, targetName);
  }

  static String? _longestEndsWithMatch(String path, Set<String> extensions) {
    String? best;
    for (final ext in extensions) {
      if (path.endsWith(ext) && (best == null || ext.length > best.length)) {
        best = ext;
      }
    }
    return best;
  }
}
