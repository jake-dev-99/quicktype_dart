// Well-known on-disk paths relative to the `quicktype_dart` package
// root. Centralized here so dev tooling, the Process backend, and
// tests all agree on where the bundled `quicktype` CLI lives instead
// of sprinkling the same literal across the codebase.

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// Relative path to the bundled `quicktype` executable produced by the
/// Node setup in `tool/`. `Process`-transport callers check this before
/// falling through to a `PATH` lookup.
const String bundledQuicktypeExeRelative = 'tool/node_modules/.bin/quicktype';

/// Full path to the bundled `quicktype` exe resolved against the
/// quicktype_dart package root, or null if the package root can't be
/// resolved or the file doesn't exist.
///
/// Uses [Isolate.resolvePackageUri] so the answer doesn't depend on
/// caller CWD — tests, build_runner, and CLI invocations all resolve
/// to the same on-disk path.
Future<String?> bundledQuicktypeExe() async {
  final root = await packageRoot();
  if (root == null) return null;
  final path = p.join(root, bundledQuicktypeExeRelative);
  return File(path).existsSync() ? path : null;
}

/// The `quicktype_dart` package root — the directory containing
/// `pubspec.yaml` — or null if it can't be resolved (e.g. when the
/// library is being AOT-compiled into a consumer binary).
Future<String?> packageRoot() async {
  try {
    final packageUri = await Isolate.resolvePackageUri(
      Uri.parse('package:quicktype_dart/quicktype_dart.dart'),
    );
    if (packageUri == null) return null;
    return p.dirname(p.dirname(packageUri.toFilePath()));
  } catch (_) {
    return null;
  }
}
