/// Base classes for quicktype command-line arguments and the barrel for every
/// language-specific arg module.
///
/// Each [Arg] subclass knows how to serialize itself into a proper argv list
/// via [Arg.argv] — separate elements, no shell escaping needed, safe for
/// `Process.run`.

export 'args/main_args.dart';
export 'args/enums.dart';
export 'args/lang_c.dart';
export 'args/lang_cpp.dart';
export 'args/lang_csharp.dart';
export 'args/lang_dart.dart';
export 'args/lang_elixir.dart';
export 'args/lang_elm.dart';
export 'args/lang_flow.dart';
export 'args/lang_go.dart';
export 'args/lang_haskell.dart';
export 'args/lang_java.dart';
export 'args/lang_javascript.dart';
export 'args/lang_kotlin.dart';
export 'args/lang_objc.dart';
export 'args/lang_php.dart';
export 'args/lang_proptypes.dart';
export 'args/lang_python.dart';
export 'args/lang_ruby.dart';
export 'args/lang_rust.dart';
export 'args/lang_scala.dart';
export 'args/lang_smithy.dart';
export 'args/lang_swift.dart';
export 'args/lang_typescript.dart';

/// Base class for a quicktype CLI argument.
///
/// The convention is **null value → argument absent**. Non-null values
/// serialize per-subclass into an argv list via [argv].
abstract class Arg<T> {
  Arg(this.name, {this.value});

  final String name;
  T? value;

  /// Serialize this argument into a list of argv elements suitable for
  /// `Process.run` (each element is one argv entry; no shell escaping).
  /// Returns an empty list when the argument should be omitted entirely.
  List<String> argv();

  /// Display form for debugging and logging. Mirrors [argv] joined by spaces.
  @override
  String toString() => argv().join(' ');
}

/// A presence-flag argument. `value == true` emits `--name`; null or false
/// emits nothing. Useful for flags like `--help` or `--alphabetize-properties`.
class SimpleArg extends Arg<bool> {
  SimpleArg(super.name, {super.value});

  @override
  List<String> argv() => value == true ? ['--$name'] : const [];
}

/// A string-valued argument. Emits `['--name', value]` when non-null.
class StringArg extends Arg<String?> {
  StringArg(super.name, {super.value});

  @override
  List<String> argv() => value == null ? const [] : ['--$name', value!];
}

/// An enum-valued argument. Emits `['--name', enum.toString()]` when set.
class EnumArg<T extends Enum> extends Arg<Enum?> {
  EnumArg(super.name, {super.value});

  @override
  List<String> argv() =>
      value == null ? const [] : ['--$name', value!.toString()];
}

/// A positive/negative toggle. `true` emits `--name`; `false` emits
/// `--no-name`; null emits nothing.
class BoolArg extends Arg<bool> {
  BoolArg(super.name, {super.value});

  @override
  List<String> argv() {
    if (value == null) return const [];
    return value! ? ['--$name'] : ['--no-$name'];
  }
}

/// A repeatable argument. Emits `--name v1 --name v2 ...` for each value.
class RepeatableArg extends Arg<List<String>> {
  RepeatableArg(super.name, List<String> values)
      : values = values,
        super(value: values);

  final List<String> values;

  @override
  List<String> argv() {
    final out = <String>[];
    for (final v in values) {
      out.addAll(['--$name', v]);
    }
    return out;
  }
}
