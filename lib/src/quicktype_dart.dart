import 'dart:convert';

import 'backend_io.dart'
    if (dart.library.js_interop) 'backend_web.dart' as backend;
import 'models/args.dart';
import 'models/renderer_options.dart';
import 'models/type.dart';

/// Selects which code-generation transport [QuicktypeDart] uses.
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
enum GenerateTransport { auto, ffi, process }

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
/// Two equivalent ways:
///
///   * **`options:` (preferred)** — a typed [RendererOptions] subclass
///     with named parameters per flag:
///
///     ```dart
///     options: const DartRendererOptions(
///       useFreezed: true,
///       nullSafety: true,
///     ),
///     ```
///
///   * **`args:` (deprecated)** — an iterable of legacy [Arg] instances:
///
///     ```dart
///     args: [DartArgs.useFreezed..value = true, DartArgs.nullSafety..value = true],
///     ```
///
/// Both paths resolve to the same `Map<String, String>` that quicktype-core
/// consumes internally. The typed [options] path is the long-term API; the
/// `args:` path will be removed in v0.4.0.
class QuicktypeDart {
  QuicktypeDart._();

  /// Generates typed source code from any JSON-encodable Dart value.
  ///
  /// See class-level docs for parameter semantics.
  static Future<String> generate({
    required String label,
    required Object data,
    required TargetType target,
    RendererOptions? options,
    Iterable<Arg> args = const [],
    GenerateTransport transport = GenerateTransport.auto,
  }) =>
      generateFromString(
        label: label,
        json: jsonEncode(data),
        target: target,
        options: options,
        args: args,
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
    Iterable<Arg> args = const [],
    GenerateTransport transport = GenerateTransport.auto,
  }) {
    final merged = _mergeOptions(options, args);
    return backend.generateFromString(
      label: label,
      json: json,
      target: target,
      rendererOptions: merged,
      transport: transport,
    );
  }

  /// Resolves either-or-both `options:` and `args:` into a single
  /// `Map<String, String>`. When both are supplied, `args:` entries
  /// override `options:` entries on key collision (legacy wins so
  /// callers mid-migration don't surprise themselves).
  static Map<String, String> _mergeOptions(
    RendererOptions? options,
    Iterable<Arg> args,
  ) {
    final merged = <String, String>{};
    if (options != null) merged.addAll(options.toRendererOptions());
    for (final arg in args) {
      final entry = arg.toRendererOption();
      if (entry != null) merged[entry.key] = entry.value;
    }
    return merged;
  }
}
