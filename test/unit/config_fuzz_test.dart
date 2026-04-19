// Property-style coverage for `Config.fromFile` / `Config.fromMap`:
// a large set of hand-rolled malformed shapes must all surface as
// `ConfigException`s with a useful message. Never as raw cast errors
// or random exceptions leaking out of dart:convert.

import 'dart:convert';
import 'dart:io';

import 'package:quicktype_dart/src/config.dart';
import 'package:test/test.dart';

void main() {
  late Directory sandbox;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('qt_fuzz_');
  });

  tearDown(() {
    sandbox.deleteSync(recursive: true);
  });

  final malformedJsonBodies = <String>[
    '[]',
    '"just a string"',
    '42',
    'null',
    'true',
    '{not json',
    '{"sources": 42}',
    '{"sources": []}',
    '{"sources": "nope"}',
    '{"sources": null, "targets": "bad"}',
    '{"targets": 42}',
    '{"targets": []}',
    '{"targets": {"unknown_lang": []}}',
    '{"targets": {"dart": "should be a list"}}',
    '{"targets": {"dart": [42]}}',
    '{"targets": {"dart": [null]}}',
    '{"targets": {"dart": [[]]}}',
    '{"sources": {"json": "not a list"}}',
    '{"sources": {"unknown_source": []}}',
    '{"sources": {"json": [42]}}',
    '{"sources": {"json": [null]}}',
    '{"sources": {"json": [{"path": 42}]}}',
  ];

  for (final body in malformedJsonBodies) {
    test('rejects ${jsonEncode(body)} cleanly', () {
      final f = File('${sandbox.path}/q.json')..writeAsStringSync(body);
      try {
        Config.fromFile(f.path);
        fail('expected ConfigException for body: $body');
      } on ConfigException {
        // expected
      } on FormatException catch (e) {
        fail('leaked FormatException for body $body: $e');
      } catch (e) {
        fail('leaked ${e.runtimeType} for body $body: $e');
      }
    });
  }

  test('Config.fromMap rejects the same bad shapes', () {
    const badMaps = <Map<String, dynamic>>[
      {'sources': 'nope'},
      {'targets': <dynamic>[]},
      {
        'targets': <String, String>{'dart': 'not a list'},
      },
      {
        'targets': <String, dynamic>{
          'dart': <int>[42]
        },
      },
    ];
    for (final m in badMaps) {
      expect(
        () => Config.fromMap(m),
        throwsA(isA<ConfigException>()),
        reason: 'expected ConfigException for: $m',
      );
    }
  });
}
