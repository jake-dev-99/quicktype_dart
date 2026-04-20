import 'package:path/path.dart' as p;

import 'type.dart';

/// Infers a [TypeEnum] value from a file path by extension.
///
/// Picks the **longest matching extension** across [candidates] so multi-dot
/// extensions (e.g. `.schema.json`) win over simpler overlapping ones
/// (`.json`). Returns `null` if nothing matches.
///
/// Example:
/// ```dart
/// inferLangType<TargetType>(TargetType.values, 'models/Foo.dart');
/// // → TargetType.dart
///
/// inferLangType<SourceType>(SourceType.values, 'models/user.schema.json');
/// // → SourceType.jsonschema (not SourceType.json)
/// ```
T? inferLangType<T extends TypeEnum>(List<T> candidates, String path) {
  final basename = p.basename(path);
  T? best;
  var bestLen = -1;
  for (final candidate in candidates) {
    for (final ext in candidate.extensions) {
      if (basename.endsWith(ext) && ext.length > bestLen) {
        best = candidate;
        bestLen = ext.length;
      }
    }
  }
  return best;
}
