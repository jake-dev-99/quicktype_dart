// Shared conversion from the `Map<String, String>` renderer-options shape
// that quicktype-core expects into the argv fragment the quicktype CLI
// accepts. Used by both the Process-transport runner and the
// QuicktypeCommand builder so any future convention change (e.g. flipping
// bool encoding) is a one-file edit.

/// Flattens [options] into `--flag value` pairs:
///
///   * `'true'`  → `--flag`
///   * `'false'` → `--no-flag`
///   * anything else → `--flag value`
List<String> rendererOptionsToArgv(Map<String, String> options) {
  final out = <String>[];
  for (final entry in options.entries) {
    switch (entry.value) {
      case 'true':
        out.add('--${entry.key}');
      case 'false':
        out.add('--no-${entry.key}');
      default:
        out.addAll(['--${entry.key}', entry.value]);
    }
  }
  return out;
}
