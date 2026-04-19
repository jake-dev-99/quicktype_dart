/// Package version string, surfaced through the CLI's `--version` flag and
/// available for library consumers that want a runtime version check.
///
/// Kept in lockstep with the `version:` field in `pubspec.yaml`. Both values
/// bump together on every release.
library;

/// The semver string for the currently-built copy of `quicktype_dart`.
const String packageVersion = '0.4.2';
