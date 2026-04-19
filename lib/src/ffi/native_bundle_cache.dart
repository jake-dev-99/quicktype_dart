// Fetch + on-disk cache + integrity verification for remote bundles on
// native targets. Used by [QtFfiRuntime.create] when the current
// [BundleSource] is [RemoteBundleSource].
//
// Cache layout:
//   <tempDir>/quicktype_dart_bundles/<url-hash>/bundle.js
//
// The URL is SHA-256-hashed (truncated) to derive a filename, so different
// versions on the same URL automatically get fresh downloads if the
// `integrity` argument changes or the cached file fails verification.

library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import '../quicktype.dart';

/// Fetches [url], writes to an on-disk cache, and returns the body as a
/// UTF-8 string ready to feed into `qt_runtime_load_bundle`.
///
/// [integrity], if supplied, must be a Subresource-Integrity-style token
/// like `'sha256-<base64>'` or `'sha384-<base64>'`. The fetch is re-tried
/// from network when the cached file doesn't match the integrity, and the
/// whole call fails if the freshly-downloaded bytes don't match either.
Future<String> fetchAndCacheBundle(Uri url, String? integrity) async {
  final cacheFile = await _cacheFileFor(url);

  if (cacheFile.existsSync()) {
    final bytes = cacheFile.readAsBytesSync();
    if (integrity == null || _matchesIntegrity(bytes, integrity)) {
      return utf8.decode(bytes);
    }
    // Integrity mismatch on cached copy → re-fetch.
  }

  final bytes = await _fetch(url);
  if (integrity != null && !_matchesIntegrity(bytes, integrity)) {
    throw QuicktypeException(
      'Bundle integrity mismatch for $url. '
      'Got ${_sriHash("sha256", bytes)}, expected $integrity.',
    );
  }
  cacheFile.parent.createSync(recursive: true);
  cacheFile.writeAsBytesSync(bytes, flush: true);
  return utf8.decode(bytes);
}

/// On-disk cache path for [url].
Future<File> _cacheFileFor(Uri url) async {
  final key = crypto.sha256
      .convert(utf8.encode(url.toString()))
      .toString()
      .substring(0, 16);
  return File(
    p.join(Directory.systemTemp.path, 'quicktype_dart_bundles', key, 'bundle.js'),
  );
}

/// Fetches [url] with a short total timeout. HTTP/HTTPS only; `file:` URLs
/// are also supported for tests + tooling.
Future<Uint8List> _fetch(Uri url) async {
  if (url.scheme == 'file') {
    return File(url.toFilePath()).readAsBytes();
  }
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await client.getUrl(url);
    final resp = await req.close();
    if (resp.statusCode != 200) {
      throw QuicktypeException(
          'GET $url returned HTTP ${resp.statusCode}');
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in resp) {
      builder.add(chunk);
    }
    return builder.toBytes();
  } finally {
    client.close(force: true);
  }
}

/// Returns true if [bytes] hash to the SRI token [integrity].
bool _matchesIntegrity(List<int> bytes, String integrity) {
  final parsed = _parseSri(integrity);
  if (parsed == null) return false;
  final actual = _sriHash(parsed.$1, bytes);
  return actual == integrity;
}

/// Parses `'sha256-<base64>'` or `'sha384-<base64>'`. Returns
/// (algorithm, base64hash) or null on bad format.
(String, String)? _parseSri(String token) {
  final idx = token.indexOf('-');
  if (idx <= 0) return null;
  final alg = token.substring(0, idx).toLowerCase();
  if (alg != 'sha256' && alg != 'sha384' && alg != 'sha512') return null;
  return (alg, token.substring(idx + 1));
}

/// Computes the SRI-format hash for [bytes] under [algorithm]
/// (one of `sha256`, `sha384`, `sha512`).
String _sriHash(String algorithm, List<int> bytes) {
  final hash = switch (algorithm) {
    'sha256' => crypto.sha256.convert(bytes),
    'sha384' => crypto.sha384.convert(bytes),
    'sha512' => crypto.sha512.convert(bytes),
    _ => throw ArgumentError('Unsupported SRI algorithm: $algorithm'),
  };
  return '$algorithm-${base64.encode(hash.bytes)}';
}
