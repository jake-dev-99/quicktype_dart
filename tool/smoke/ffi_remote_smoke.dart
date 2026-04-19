// Remote-bundle FFI smoke. Builds a file:// URL pointing at the built
// web asset (prelude + quicktype_bundle.js concat) and feeds it through
// the new BundleSource.remote path. Proves the fetch-cache-load loop
// end-to-end against a known-good bundle without hitting the network.
//
// Prerequisites:
//   1. `cmake --build build/native` has produced libquicktype_dart.dylib
//   2. `assets/quicktype_bundle.js` exists (built at bundle-build time)

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:quicktype_dart/src/ffi/ffi_runtime.dart';

Future<void> main() async {
  final pkgRoot = Directory.current.path;
  final bundleFile = File(p.join(pkgRoot, 'assets', 'quicktype_bundle.js'));
  if (!bundleFile.existsSync()) {
    stderr
        .writeln('FAIL: ${bundleFile.path} not found — build the bundle first');
    exit(1);
  }
  final url = Uri.file(bundleFile.absolute.path);
  stdout.writeln('Loading bundle from: $url');

  final rt = await QtFfiRuntime.create(
    bundleSource: BundleSource.remote(url),
  );

  final out = await rt.generate(
    label: 'User',
    json: '{"id":1,"name":"Jake","active":true}',
    target: TargetType.dart,
  );
  if (!out.contains('class User')) {
    stderr.writeln('FAIL: generated output missing `class User`');
    stderr.writeln(out);
    exit(1);
  }
  stdout.writeln('OK — remote BundleSource produced ${out.length} chars');
  rt.dispose();
}
