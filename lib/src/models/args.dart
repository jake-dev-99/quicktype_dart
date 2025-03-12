/// Abstract base class for all quicktype command-line arguments.
///
/// This provides the foundation for different argument types
/// such as names, string values, and boolean toggles.

export 'args/main_args.dart';
export 'args/enums.dart';
export 'args/lang_dart.dart';
export 'args/lang_java.dart';
export 'args/lang_javascript.dart';
export 'args/lang_kotlin.dart';
export 'args/lang_objc.dart';
export 'args/lang_php.dart';
export 'args/lang_swift.dart';
export 'args/lang_typescript.dart';

abstract class Arg<T> {
  /// Creates a new argument with the specified name
  Arg(
    this.name, {
    this.value,
  });
  final String? prefix = '';
  final String? suffix = '';
  final String name;
  T? value;

  /// Returns arg formatted as "--{name} {value}"
  /// In the case of a null value, the value is omitted
  @override
  String toString() =>
      ('--${_prepString(prefix)}${_prepString(name)} ${_prepString(suffix)}')
          .trim();
}

/// A simple name argument that takes no value (e.g., --help).
///
/// Example usage:
/// ```dart
/// final helpArg = SimpleArg('help');
///; // Targets: --help
/// ```
class SimpleArg extends Arg<bool> {
  /// Creates a simple name argument
  ///
  /// The [name] should not include the -- prefix
  @override
  SimpleArg(super.name, {super.value});
}

/// An argument that takes a string value (e.g., --target filename.dart).
///
/// Handles proper quoting and escaping of the value when necessary.
///
/// Example usage:
/// ```dart
/// final targetArg = StringArg('target', 'target.dart');
///; // Targets: --target "target.dart"
/// ```
class StringArg extends Arg<String?> {
  /// Creates a string argument with a value
  ///
  /// [name] should not include the -- prefix
  /// [value] is the string value to pass to the argument

  @override
  get suffix => this.value;
  StringArg(super.name, {super.value});
}

/// An argument that takes a string value (e.g., --target filename.dart).
///
/// Handles proper quoting and escaping of the value when necessary.
///
/// Example usage:
/// ```dart
/// final targetArg = StringArg('target', 'target.dart');
///; // Targets: --target "target.dart"
/// ```
class EnumArg<T extends Enum> extends Arg<Enum?> {
  /// Creates a string argument with a value
  ///
  /// [name] should not include the -- prefix
  /// [value] is the string value to pass to the argument

  @override
  get suffix => this.value.toString();
  EnumArg(super.name, {super.value});
}

/// A boolean toggle argument that can be represented as either
/// --feature or --no-feature depending on the value.
///
/// Example usage:
/// ```dart
/// final combineArg = BoolArg('combine-classes', true);
///; // Targets: --combine-classes
///
/// final noCombineArg = BoolArg('combine-classes', false);
///; // Targets: --no-combine-classes
/// ```
class BoolArg extends Arg<bool> {
//! Note to future Jake - enabled and value will not pare nicely here - keep them separated!
  @override
  get prefix => (super.value ?? false) ? '' : 'no-';

  /// Creates a boolean toggle argument
  ///
  /// The [name] should be the positive form withtarget the -- prefix
  /// The [value] determines whether to use the positive or negative form
  BoolArg(super.name, {super.value});
}

/// An argument that can be repeated multiple times with different values
/// (e.g., --src file1.json --src file2.json)
///
/// Example usage:
/// ```dart
/// final srcArgs = RepeatableArg('src', ['file1.json', 'file2.json']);
///; // Targets: --src "file1.json" --src "file2.json"
/// ```
class RepeatableArg extends Arg<List<String>> {
  /// List of values for this repeatable argument
  final List<String> values;

  /// Creates a repeatable argument with multiple values
  ///
  /// The [name] should not include the -- prefix
  /// The [values] is a list of values to pass to repeated instances of the argument
  RepeatableArg(super.name, this.values);

  /// Returns the formatted repeatable argument string
  @override
  get suffix => values.join(' ');
}

String _prepString(String? s) {
  return s == null
      ? ''
      : s
          .toString()
          .replaceAll('"', '\"') // Escape double quotes
          .replaceAll(" ", "") // Remove spaces
          .replaceAll("'", '\"') // Replace single quotes with double quotes
          .replaceAll('--', '') // Remove double dashes (reserved)
          .replaceAll('_', '') // Remove underscores
          .trim();
}
