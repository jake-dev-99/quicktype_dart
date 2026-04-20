import 'package:logging/logging.dart';

/// Package-private logging facade routing through
/// `Logger('quicktype')` from `package:logging`.
///
/// Library code emits structured diagnostic events via [info],
/// [warning], [severe], etc. — these are **silent by default** because
/// `package:logging` doesn't install a root listener. Consumers who
/// want visibility attach one:
///
/// ```dart
/// import 'package:logging/logging.dart';
///
/// Logger.root.level = Level.INFO;
/// Logger.root.onRecord.listen((r) {
///   stdout.writeln('[${r.level.name}] ${r.loggerName}: ${r.message}');
/// });
/// ```
///
/// `QuicktypeCLI.run` installs that kind of listener so users running
/// `dart run quicktype_dart …` see progress + errors from deep inside
/// the library.
///
/// **There is no `Log.off()`.** Messages meant to be user-visible
/// unconditionally (CLI --help text, --version, top-level errors) are
/// written directly to `stdout`/`stderr` at the call site instead of
/// sneaking through a "log at OFF level" trick that nothing actually
/// listens to.
///
/// Pass [className] to route under a `quicktype.<subsystem>` child
/// logger so subscribers can filter.
class Log {
  Log._();

  static final Logger _root = Logger('quicktype');

  static Logger _logger(String? subsystem) =>
      subsystem == null ? _root : Logger('quicktype.$subsystem');

  /// Logs at [Level.SHOUT] — highest severity, rarely used.
  static void shout(String message, [String? className]) =>
      _logger(className).shout(message);

  /// Errors that prevent the operation from completing.
  static void severe(String message, [String? className]) =>
      _logger(className).severe(message);

  /// Recoverable issues the caller should know about.
  static void warning(String message, [String? className]) =>
      _logger(className).warning(message);

  /// Routine progress events.
  static void info(String message, [String? className]) =>
      _logger(className).info(message);

  /// Configuration decisions.
  static void config(String message, [String? className]) =>
      _logger(className).config(message);

  /// Useful debug detail.
  static void fine(String message, [String? className]) =>
      _logger(className).fine(message);

  /// Verbose debug detail.
  static void finer(String message, [String? className]) =>
      _logger(className).finer(message);

  /// The noisiest tier, e.g. per-token tracing.
  static void finest(String message, [String? className]) =>
      _logger(className).finest(message);
}
