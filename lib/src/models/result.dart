library quicktype.models.quicktype_result;

/// Result of a quicktype execution
class QuicktypeResult {
  /// Path to the source file
  final String sourcePath;

  /// Path to the generated target file
  final String targetPath;

  /// Whether the operation was successful
  final bool success;

  /// Error message if the operation failed
  final String? errorMessage;

  /// Standard target from the quicktype process
  final String? stdout;

  /// Standard error from the quicktype process
  final String? stderr;

  final String? targetContent;

  /// Creates a successful result
  QuicktypeResult.success({
    required this.sourcePath,
    required this.targetPath,
    this.targetContent,
    this.stdout,
    this.stderr,
  })  : success = true,
        errorMessage = null;

  /// Creates a failed result
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
