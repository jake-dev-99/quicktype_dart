// Web backend — used on Flutter Web and any other `dart:js_interop`-capable
// target. Selected via conditional import in [quicktype_dart.dart].
//
// Loads the bundled quicktype-core JS as a script asset on first call,
// then invokes `globalThis.qtConvert` via js_interop. No subprocess, no FFI.

library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'bundle_source.dart';
import 'models/type.dart';
import 'quicktype.dart';
import 'quicktype_dart.dart' show GenerateTransport, QuicktypeDart;

/// Matches [backend_io.generateFromString] signature. [transport] is
/// honored as follows on web:
///   * [GenerateTransport.auto] → web (the only option).
///   * [GenerateTransport.ffi] / [GenerateTransport.process] → throws
///     [UnsupportedError] since neither is available in a browser.
Future<String> generateFromString({
  required String label,
  required String json,
  required TargetType target,
  required Map<String, String> rendererOptions,
  required GenerateTransport transport,
}) async {
  if (transport == GenerateTransport.ffi) {
    throw UnsupportedError(
        'GenerateTransport.ffi is not available on Flutter Web; '
        'use GenerateTransport.auto.');
  }
  if (transport == GenerateTransport.process) {
    throw UnsupportedError(
        'GenerateTransport.process is not available on Flutter Web; '
        'use GenerateTransport.auto.');
  }

  await _ensureBundleLoaded();

  try {
    final resultPromise = _qtConvert(
      target.argName.toJS,
      label.toJS,
      json.toJS,
      jsonEncode(rendererOptions).toJS,
    );
    final result = await resultPromise.toDart;
    return (result as JSString).toDart;
  } catch (e) {
    throw QuicktypeException('Web qtConvert failed: $e');
  }
}

// --- Bundle loading -------------------------------------------------------

Future<void>? _loadFuture;

/// Injects `<script src="…/quicktype_bundle.js">` once and resolves when
/// `globalThis.qtConvert` becomes defined.
Future<void> _ensureBundleLoaded() {
  return _loadFuture ??= _loadBundle();
}

Future<void> _loadBundle() async {
  if (_qtConvertRaw != null) return;

  final source = QuicktypeDart.bundleSource;
  final url = switch (source) {
    EmbeddedBundleSource() => _embeddedAssetUrl,
    RemoteBundleSource(:final url) => url.toString(),
  };
  final integrity = switch (source) {
    EmbeddedBundleSource() => null,
    RemoteBundleSource(:final integrity) => integrity,
  };

  final existing = web.document
      .querySelector('script[data-quicktype-dart="bundle"]');
  if (existing == null) {
    final script = web.document.createElement('script') as web.HTMLScriptElement
      ..src = url
      ..async = true
      ..setAttribute('data-quicktype-dart', 'bundle');
    if (integrity != null) {
      script.setAttribute('integrity', integrity);
      script.setAttribute('crossorigin', 'anonymous');
    }

    final completer = Completer<void>();
    script.onLoad.listen((_) => completer.complete());
    script.onError.listen((e) => completer.completeError(
        QuicktypeException('Failed to load $url: $e')));
    web.document.head!.appendChild(script);
    await completer.future;
  } else {
    // Wait for an already-injected script to finish loading.
    // Budget: 5s should be more than enough for a 2.9MB cached asset.
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (_qtConvertRaw == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  if (_qtConvertRaw == null) {
    throw QuicktypeException(
      'quicktype_dart: bundle loaded but globalThis.qtConvert is not '
      'defined. The JS bundle may be corrupt.',
    );
  }
}

/// Path the Flutter Web tool serves plugin assets under. Used for
/// [BundleSource.embedded].
const _embeddedAssetUrl =
    'assets/packages/quicktype_dart/assets/quicktype_bundle.js';

// --- js_interop bindings --------------------------------------------------

@JS('qtConvert')
external JSFunction? _qtConvertRaw;

JSPromise<JSAny?> _qtConvert(
  JSString lang,
  JSString name,
  JSString json,
  JSString optionsJson,
) =>
    _qtConvertRaw!.callAsFunction(
      null,
      lang,
      name,
      json,
      optionsJson,
    ) as JSPromise<JSAny?>;
