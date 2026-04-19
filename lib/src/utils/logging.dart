library;

import 'dart:developer';

import 'package:logging/logging.dart';

/// Static logging facade routing through `dart:developer.log` under the
/// `quicktype` logger namespace.
///
/// Consumers can tune verbosity by attaching a listener to
/// `Logger('quicktype')` from `package:logging`. Each method maps to the
/// corresponding [Level] — callers typically reach for [info], [warning],
/// and [severe].
///
/// Pass an optional [className] to namespace under `quicktype.$className` so
/// filtering by subsystem works.
class Log {
  Log._();

  /// Logs at [Level.OFF] (disabled by default). Used for user-facing CLI
  /// output that should be visible even when logging is silenced.
  static void off(String message, [String? className]) =>
      _log(message, Level.OFF.value, className);

  /// Logs at [Level.SHOUT] — highest severity, rarely used.
  static void shout(String message, [String? className]) =>
      _log(message, Level.SHOUT.value, className);

  /// Logs at [Level.SEVERE] — errors that prevent the operation from completing.
  static void severe(String message, [String? className]) =>
      _log(message, Level.SEVERE.value, className);

  /// Logs at [Level.WARNING] — recoverable issues the caller should know about.
  static void warning(String message, [String? className]) =>
      _log(message, Level.WARNING.value, className);

  /// Logs at [Level.INFO] — routine progress events.
  static void info(String message, [String? className]) =>
      _log(message, Level.INFO.value, className);

  /// Logs at [Level.CONFIG] — configuration decisions.
  static void config(String message, [String? className]) =>
      _log(message, Level.CONFIG.value, className);

  /// Logs at [Level.FINE] — useful debug detail.
  static void fine(String message, [String? className]) =>
      _log(message, Level.FINE.value, className);

  /// Logs at [Level.FINER] — verbose debug detail.
  static void finer(String message, [String? className]) =>
      _log(message, Level.FINER.value, className);

  /// Logs at [Level.FINEST] — the noisiest tier, e.g. per-token tracing.
  static void finest(String message, [String? className]) =>
      _log(message, Level.FINEST.value, className);

  /// Logs at [Level.ALL] — always visible, for completeness.
  static void all(String message, [String? className]) =>
      _log(message, Level.ALL.value, className);

  static void _log(String message, int level, [String? className]) {
    final name = className == null ? 'quicktype' : 'quicktype.$className';
    log(message, name: name, level: level);
  }
}
