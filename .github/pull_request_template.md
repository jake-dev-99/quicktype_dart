## Summary

<!-- What changed and why, in 1–3 bullets. Link the plan item or issue if any. -->

## Test plan

<!-- Checklist of what you ran locally. Every box should be ticked before merge. -->

- [ ] `dart format --set-exit-if-changed lib test tool bin example`
- [ ] `dart analyze --fatal-infos --fatal-warnings`
- [ ] `dart test test/unit`
- [ ] `dart test test/integration --tags=integration` (if touching backend / generate path)
- [ ] `dart run tool/sync_version.dart`
- [ ] `dart run tool/api_snapshot.dart` (update via `--write` + add CHANGELOG entry if the surface moved)

## Changelog

<!-- One sentence describing the user-visible change. Skip for refactors with no observable effect. -->

## Breaking?

- [ ] Yes — documented under `### Removed — breaking` or `### Changed — breaking` in `CHANGELOG.md` with a migration snippet.
- [ ] No.

<!-- Leave this footer line for Claude Code-authored PRs. -->
🤖 Generated with [Claude Code](https://claude.com/claude-code)
