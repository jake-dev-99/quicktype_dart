import 'dart:convert';

import 'backend_io.dart' if (dart.library.js_interop) 'backend_web.dart'
    as backend;
import 'bundle_source.dart';
import 'models/renderer_options.dart';
import 'models/type.dart';

/// Selects which code-generation transport [QuicktypeDart] uses.
///
/// **Prefer [auto]** — the non-auto values are escape hatches for tests,
/// benchmarks, and environments where the default selection picks wrong.
/// Pinning to [ffi] or [process] forces a specific runtime even when a
/// faster or more-portable one is available on the current platform.
///
/// * [auto] — default. On Flutter Web, picks the `dart:js_interop` web
///   path. On native targets, prefers the in-process FFI runtime when
///   available and falls back to [process] otherwise.
/// * [ffi] — require the embedded QuickJS runtime. Throws on Flutter Web
///   (`dart:ffi` unavailable) and on native targets where the FFI plugin
///   isn't loaded.
/// * [process] — require shelling out to the `quicktype` Node CLI.
///   Throws on Flutter Web (`dart:io` unavailable). Useful for native
///   dev tooling or environments where the FFI plugin isn't built.
enum GenerateTransport {
  /// Default. Picks the best-available transport per platform (FFI on
  /// native, web on browser, Process as the last-resort fallback).
  auto,

  /// Force the in-process QuickJS FFI runtime. Fastest after warm-up;
  /// unavailable on web.
  ffi,

  /// Force the `quicktype` Node CLI subprocess. Unavailable on web;
  /// requires `npm install -g quicktype` or the bundled tool/ setup.
  process,
}

/// Entry point for ad-hoc, runtime JSON → typed-code conversion.
///
/// Two forms:
///
///   * [generate] — for any JSON-encodable Dart value (Map, List, etc.)
///   * [generateFromString] — for raw JSON text you already have
///
/// ```dart
/// final dartSource = await QuicktypeDart.generate(
///   label: 'User',
///   data: [{'id': 1, 'name': 'Jake'}],
///   target: TargetType.dart,
///   options: const DartRendererOptions(useFreezed: true),
/// );
/// ```
///
/// ### Transports
///
/// Three runtimes ship, selected via [GenerateTransport]:
///
/// * **FFI** (native default) — embedded QuickJS running quicktype-core's
///   bundled JS directly in-process. Available on macOS, iOS, Linux,
///   Windows, and Android. ~ms per call after one-time warm-up.
/// * **Process** — shells out to the `quicktype` Node CLI. Requires
///   `npm install -g quicktype`. Useful for native dev tooling.
/// * **Web** — uses `dart:js_interop` to run the same bundled JS in the
///   browser's native JS engine. Picked automatically on Flutter Web.
///
/// ### Passing language options
///
/// Construct a typed [RendererOptions] subclass and pass it via
/// [options]:
///
/// ```dart
/// options: const DartRendererOptions(
///   useFreezed: true,
///   nullSafety: true,
/// ),
/// ```
///
/// One subclass per target language — `DartRendererOptions`,
/// `KotlinRendererOptions`, `SwiftRendererOptions`, etc. Null fields
/// are omitted, so unset options inherit quicktype-core's defaults.
class QuicktypeDart {
  QuicktypeDart._();

  /// Where the quicktype-core JS bundle is loaded from. Defaults to
  /// [BundleSource.embedded]. Assign **before the first `generate` call**;
  /// afterwards the loaded bundle is cached for the process lifetime
  /// (web: the page lifetime) and later reassignments are ignored for any
  /// runtime that already picked one up.
  ///
  /// ```dart
  /// QuicktypeDart.bundleSource = BundleSource.remote(
  ///   Uri.parse('https://cdn.example.com/quicktype-bundle.js'),
  /// );
  /// ```
  static BundleSource bundleSource = const BundleSource.embedded();

  /// Maximum wall-clock duration for a single `quicktype` subprocess run
  /// via [GenerateTransport.process]. A hung child no longer blocks the
  /// caller (or build_runner) forever — the process is terminated and a
  /// [QuicktypeException] is thrown when this elapses. Defaults to 5
  /// minutes; override for generations that legitimately take longer.
  static Duration processTimeout = const Duration(minutes: 5);

  /// Generates typed source code from any JSON-encodable Dart value.
  ///
  /// See class-level docs for parameter semantics.
  static Future<String> generate({
    required String label,
    required Object data,
    required TargetType target,
    RendererOptions? options,
    GenerateTransport transport = GenerateTransport.auto,
  }) =>
      generateFromString(
        label: label,
        json: jsonEncode(data),
        target: target,
        options: options,
        transport: transport,
      );

  /// Generates typed source code from a raw JSON document string.
  ///
  /// Skip `jsonEncode`-ing when you already have the document as a string
  /// (reading a file, a network response, etc). See [generate] for
  /// parameter semantics.
  static Future<String> generateFromString({
    required String label,
    required String json,
    required TargetType target,
    RendererOptions? options,
    GenerateTransport transport = GenerateTransport.auto,
  }) {
    final rendererOptions =
        options?.toRendererOptions() ?? const <String, String>{};
    return backend.generateFromString(
      label: label,
      json: json,
      target: target,
      rendererOptions: rendererOptions,
      transport: transport,
    );
  }
}
