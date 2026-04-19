/// The outcome of a single [Quicktype.execute] call — success or failure,
/// plus captured stdout/stderr from the underlying quicktype subprocess.
///
/// Constructed via [QuicktypeResult.success] or [QuicktypeResult.failure];
/// use [success] to branch.
library;

class QuicktypeResult {
  /// Source file that was converted.
  final String sourcePath;

  /// Target file that was (or would have been) generated.
  final String targetPath;

  /// `true` when quicktype exited 0.
  final bool success;

  /// Error message when [success] is `false`, otherwise `null`.
  final String? errorMessage;

  /// Captured stdout from the quicktype subprocess, if available.
  final String? stdout;

  /// Captured stderr from the quicktype subprocess, if available.
  final String? stderr;

  /// The generated target content, if the runner read the output back in.
  /// Often `null` — prefer reading [targetPath] yourself.
  final String? targetContent;

  /// Constructs a successful result.
  QuicktypeResult.success({
    required this.sourcePath,
    required this.targetPath,
    this.targetContent,
    this.stdout,
    this.stderr,
  })  : success = true,
        errorMessage = null;

  /// Constructs a failed result.
  QuicktypeResult.failure({
    required this.sourcePath,
    required this.targetPath,
    required this.errorMessage,
    this.targetContent,
    this.stdout,
    this.stderr,
  }) : success = false;

  @override
  String toString() => success
      ? 'Successfully generated $targetPath from $sourcePath'
      : 'Failed to generate $targetPath from $sourcePath: $errorMessage';
}
