import 'package:quicktype_dart/quicktype_dart.dart';
import 'package:quicktype_dart/src/utils/type_infer.dart';
import 'package:test/test.dart';

void main() {
  group('inferLangType', () {
    test('resolves a TargetType from a file extension', () {
      expect(inferLangType<TargetType>(TargetType.values, 'foo/bar.dart'),
          TargetType.dart);
      expect(inferLangType<TargetType>(TargetType.values, 'models/User.kt'),
          TargetType.kotlin);
      expect(inferLangType<TargetType>(TargetType.values, 'lib/User.swift'),
          TargetType.swift);
    });

    test('resolves a SourceType from a JSON Schema extension', () {
      expect(
        inferLangType<SourceType>(SourceType.values, 'models/user.schema.json'),
        SourceType.jsonschema,
      );
    });

    test('returns null for an unknown extension', () {
      expect(inferLangType<TargetType>(TargetType.values, 'data.txt'), isNull);
    });
  });
}
