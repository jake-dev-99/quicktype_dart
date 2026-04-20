// Web backend — used on Flutter Web and any other `dart:js_interop`-capable
// target. Selected via conditional import in [facade.dart].
//
// Loads the bundled quicktype-core JS as a script asset on first call,
// then invokes `globalThis.qtConvert` via js_interop. No subprocess, no FFI.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'bundle_source.dart';
import 'facade.dart' show GenerateTransport, QuicktypeDart;
import 'models/type.dart';
import 'quicktype.dart';

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

/// Wall-clock ceiling for waiting on an already-injected `<script>` tag
/// whose load event we can't observe directly. Generous enough to cover
/// cold cache fetches; tight enough to surface real breakage quickly.
const Duration _bundleLoadTimeout = Duration(seconds: 15);

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

  final existing =
      web.document.querySelector('script[data-quicktype-dart="bundle"]');
  if (existing == null) {
    await _injectAndWait(url, integrity);
  } else {
    await _waitForExistingScript(existing as web.HTMLScriptElement, url);
  }

  if (_qtConvertRaw == null) {
    throw QuicktypeException(
      'quicktype_dart: the bundle script finished loading but '
      'globalThis.qtConvert is not defined. The JS bundle at $url is '
      'either corrupt or not a quicktype_dart bundle.',
    );
  }
}

/// Creates a fresh `<script>` tag, attaches load/error listeners that are
/// cancelled on resolution, and waits for one of: load, error, or timeout.
Future<void> _injectAndWait(String url, String? integrity) async {
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..src = url
    ..async = true
    ..setAttribute('data-quicktype-dart', 'bundle');
  if (integrity != null) {
    script.setAttribute('integrity', integrity);
    script.setAttribute('crossorigin', 'anonymous');
  }

  final parent =
      web.document.head ?? web.document.body ?? web.document.documentElement;
  if (parent == null) {
    throw QuicktypeException(
      'quicktype_dart: document has no <head>, <body>, or <html> to '
      'attach the bundle script to. Page may be tearing down.',
    );
  }

  final completer = Completer<void>();
  final loadSub = script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  final errorSub = script.onError.listen((e) {
    if (!completer.isCompleted) {
      completer.completeError(
        QuicktypeException('Failed to load $url: $e'),
      );
    }
  });

  try {
    parent.appendChild(script);
    await completer.future.timeout(
      _bundleLoadTimeout,
      onTimeout: () => throw QuicktypeException(
        'quicktype_dart: timed out after ${_bundleLoadTimeout.inSeconds}s '
        'loading the bundle script at $url.',
      ),
    );
  } finally {
    await loadSub.cancel();
    await errorSub.cancel();
  }
}

/// Someone else injected the tag (or we did, in a previous isolate).
/// We can't rely on listeners — if the script already finished loading
/// before this code ran, no further event will fire. Race its
/// (possibly-pending) load/error events against a wall-clock deadline,
/// with `qtConvert` going live as a third success signal.
Future<void> _waitForExistingScript(
  web.HTMLScriptElement script,
  String url,
) async {
  final completer = Completer<void>();
  final loadSub = script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  final errorSub = script.onError.listen((e) {
    if (!completer.isCompleted) {
      completer.completeError(
        QuicktypeException('Failed to load $url: $e'),
      );
    }
  });

  try {
    await _pollForQtConvert(completer);
    if (!completer.isCompleted) {
      if (_qtConvertRaw != null) {
        completer.complete();
      } else {
        throw QuicktypeException(
          'quicktype_dart: timed out after ${_bundleLoadTimeout.inSeconds}s '
          'waiting for the already-injected <script data-quicktype-dart> tag '
          'to define globalThis.qtConvert. The script may have errored '
          'outside our observation window, or the page is under heavy load.',
        );
      }
    }
    await completer.future;
  } finally {
    await loadSub.cancel();
    await errorSub.cancel();
  }
}

/// Polls `_qtConvertRaw` with exponential backoff up to
/// [_bundleLoadTimeout]. Returns early as soon as [completer] resolves —
/// the completer fires from the caller's onLoad/onError listeners when
/// the script dispatches those events.
Future<void> _pollForQtConvert(Completer<void> completer) async {
  final start = DateTime.now();
  var delayMs = 2;
  while (!completer.isCompleted &&
      _qtConvertRaw == null &&
      DateTime.now().difference(start) < _bundleLoadTimeout) {
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    if (delayMs < 100) delayMs *= 2;
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
