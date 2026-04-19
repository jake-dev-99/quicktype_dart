import 'dart:convert';

import 'backend_io.dart'
    if (dart.library.js_interop) 'backend_web.dart' as backend;
import 'models/args.dart';
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
class QuicktypeDart {
  QuicktypeDart._();

  /// Generates typed source code from any JSON-encodable Dart value.
  ///
  /// [data] may be any value `dart:convert`'s [jsonEncode] accepts —
  /// a [Map], [List], [num], [String], [bool], or a nested composition
  /// thereof. Anything else throws [JsonUnsupportedObjectError].
  ///
  /// [label] becomes the top-level type name in the generated code.
  ///
  /// [target] selects the output language.
  ///
  /// [args] carries language-specific flags — e.g. for Dart:
  /// `[DartArgs.useFreezed..value = true, DartArgs.nullSafety..value = true]`.
  /// See the `*Args` classes for each target language. All three transports
  /// honor args.
  ///
  /// [transport] picks the runtime — see [GenerateTransport]. Defaults to
  /// [GenerateTransport.auto].
  ///
  /// Returns the generated source as a string. Throws [QuicktypeException]
  /// on failure.
  static Future<String> generate({
    required String label,
    required Object data,
    required TargetType target,
    Iterable<Arg> args = const [],
    GenerateTransport transport = GenerateTransport.auto,
  }) =>
      generateFromString(
        label: label,
        json: jsonEncode(data),
        target: target,
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
    Iterable<Arg> args = const [],
    GenerateTransport transport = GenerateTransport.auto,
  }) =>
      backend.generateFromString(
        label: label,
        json: json,
        target: target,
        args: args,
        transport: transport,
      );
}
