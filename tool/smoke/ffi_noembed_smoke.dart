// No-embed smoke: exercises a quicktype_dart native library built with
// -DQT_EMBED_BUNDLE=OFF. Configures BundleSource.remote to a file:// URL
// pointing at assets/quicktype_bundle.js (the prelude+bundle concat),
// loads it via qt_runtime_load_bundle, and generates a type.
//
// Run after:
//   cmake -S native -B build/native-noembed -DQT_EMBED_BUNDLE=OFF
//   cmake --build build/native-noembed

import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:quicktype_dart/src/ffi/ffi_runtime.dart';
import 'package:quicktype_dart/src/ffi/qt_shim_bindings.dart';

/// Platform-specific shared-library filename.
String get _dylibName {
  if (Platform.isMacOS) return 'libquicktype_dart.dylib';
  if (Platform.isWindows) return 'quicktype_dart.dll';
  return 'libquicktype_dart.so';
}

Future<void> main() async {
  final pkgRoot = Directory.current.path;
  // Accept either build/native-noembed/ (split-build) or
  // build/native/ (single-build with -DQT_EMBED_BUNDLE=OFF) — CI uses
  // the latter since it skips the two-way copy dance below.
  final splitBuild =
      File(p.join(pkgRoot, 'build', 'native-noembed', _dylibName));
  final singleBuild = File(p.join(pkgRoot, 'build', 'native', _dylibName));
  final dylib = splitBuild.existsSync() ? splitBuild : singleBuild;
  if (!dylib.existsSync()) {
    stderr.writeln('FAIL: $_dylibName not found at ${splitBuild.path} '
        'or ${singleBuild.path} — build with -DQT_EMBED_BUNDLE=OFF first');
    exit(1);
  }

  // Prove the embedded path is actually gone: call qt_runtime_load_embedded
  // directly and check for rc == -2.
  final lib = DynamicLibrary.open(dylib.absolute.path);
  final bindings = QtShimBindings(lib);
  final h = bindings.qtRuntimeCreate();
  final rc = bindings.qtRuntimeLoadEmbedded(h);
  bindings.qtRuntimeDestroy(h);
  if (rc != -2) {
    stderr.writeln('FAIL: expected rc==-2 from qt_runtime_load_embedded on '
        'no-embed build, got $rc');
    exit(1);
  }
  stdout.writeln('OK — qt_runtime_load_embedded returned -2 as expected');

  // Now run end-to-end via BundleSource.remote(file://...).
  // When the caller used a split-build layout (build/native-noembed/),
  // copy the no-embed binary over build/native/ so QtFfiRuntime's
  // default resolver picks it up. For single-build layouts the dylib is
  // already where it needs to be.
  final devPath = File(p.join(pkgRoot, 'build', 'native', _dylibName));
  final backup = File('${devPath.path}.embed-backup');
  final needsSwap = dylib.path != devPath.path;
  if (needsSwap) {
    if (devPath.existsSync() && !backup.existsSync()) {
      devPath.copySync(backup.path);
    }
    dylib.copySync(devPath.path);
  }
  try {
    final bundle = File(p.join(pkgRoot, 'assets', 'quicktype_bundle.js'));
    final rt = await QtFfiRuntime.create(
      bundleSource: BundleSource.remote(Uri.file(bundle.absolute.path)),
    );
    final out = await rt.generate(
      label: 'User',
      json: '{"id":1,"name":"Jake","active":true}',
      target: TargetType.dart,
    );
    rt.dispose();
    if (!out.contains('class User')) {
      stderr.writeln('FAIL: missing `class User`');
      stderr.writeln(out);
      exit(1);
    }
    stdout.writeln('OK — no-embed build + remote bundle produced '
        '${out.length} chars');
  } finally {
    if (needsSwap && backup.existsSync()) {
      backup.copySync(devPath.path);
      backup.deleteSync();
    }
  }
}
