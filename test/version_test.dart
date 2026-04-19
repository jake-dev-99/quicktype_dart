import 'dart:io';

import 'package:quicktype_dart/src/version.dart';
import 'package:test/test.dart';

/// Guards against version drift: `lib/src/version.dart` must mirror
/// `pubspec.yaml`. Batch B will automate the sync; this test catches
/// manual edits that forget one half.
void main() {
  test('packageVersion matches pubspec.yaml version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull,
        reason: 'pubspec.yaml must declare a version: field');
    expect(packageVersion, equals(match!.group(1)!.trim()));
  });
}
