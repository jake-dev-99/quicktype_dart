// Diagnostic shell formatting — produces a copy-pastable single line
// from an (executable, argv) pair. Used when surfacing subprocess
// failures so the reader can re-run the exact command by hand.
//
// We never pass anything through a shell (Process.run takes argv
// directly), so this is strictly for human-readable error messages.

/// Formats [exe] + [argv] as a single line where any entry containing
/// whitespace or special shell characters is single-quoted.
String formatCommand(String exe, List<String> argv) {
  final parts = [exe, ...argv.map(shellQuote)];
  return parts.join(' ');
}

/// Quotes [s] so it can be pasted into a POSIX shell unambiguously.
/// Conservative — skips quoting when every character is in a safe set.
/// Not a shell-injection defense; callers must not send the output
/// back through a shell.
String shellQuote(String s) {
  if (s.isEmpty) return "''";
  final safe = RegExp(r'^[A-Za-z0-9_\-+=:,./@%]+$');
  if (safe.hasMatch(s)) return s;
  return "'${s.replaceAll("'", r"'\''")}'";
}
