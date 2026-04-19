// Guards the build_runner output for `example/lib/models/user.qt.json`.
//
// The generated file is checked in so CI can verify drift without
// running a full build; to regenerate locally:
//
//     cd example && dart run build_runner build --delete-conflicting-outputs
//     dart format lib/models
//
// The `dart format` pass normalizes quicktype's 4-space indent to the
// project's 2-space style — both the CI drift check and the committed
// file assume that pass has happened.
//
// If this test starts failing, someone either changed the input fixture
// without regenerating, or the quicktype_dart builder changed its
// output contract — both warrant a CHANGELOG entry.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('example build_runner output', () {
    late String generated;

    setUpAll(() {
      generated = File('lib/models/user.dart').readAsStringSync();
    });

    test('emits a User class', () {
      expect(generated, contains('class User'));
    });

    test('emits a Profile class', () {
      expect(generated, contains('class Profile'));
    });

    test('uses --just-types (no fromJson scaffolding)', () {
      expect(generated, isNot(contains('fromJson')));
      expect(generated, isNot(contains('toJson')));
    });

    test('references input field names', () {
      expect(generated, contains('id'));
      expect(generated, contains('name'));
      expect(generated, contains('email'));
      expect(generated, contains('roles'));
      expect(generated, contains('profile'));
      expect(generated, contains('age'));
      expect(generated, contains('active'));
      expect(generated, contains('joinedAt'));
    });
  });
}
