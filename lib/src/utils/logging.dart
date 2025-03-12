import 'dart:developer';
import 'package:logging/logging.dart';

class Log {
  static OFF(String message, [String? className]) =>
      _log(message, Level.OFF.value, className);

  static SHOUT(String message, [String? className]) =>
      _log(message, Level.SHOUT.value, className);

  static SEVERE(String message, [String? className]) =>
      _log(message, Level.SEVERE.value, className);

  static WARNING(String message, [String? className]) =>
      _log(message, Level.WARNING.value, className);

  static INFO(String message, [String? className]) =>
      _log(message, Level.INFO.value, className);

  static CONFIG(String message, [String? className]) =>
      _log(message, Level.CONFIG.value, className);

  static FINE(String message, [String? className]) =>
      _log(message, Level.FINE.value, className);

  static FINER(String message, [String? className]) =>
      _log(message, Level.FINER.value, className);

  static FINEST(String message, [String? className]) =>
      _log(message, Level.FINEST.value, className);

  static ALL(String message, [String? className]) =>
      _log(message, Level.ALL.value, className);

  static _log(String message, int level, [String? className]) {
    if (className == null) {
      log(message, name: 'quicktype', level: level);
    } else {
      log(message, name: 'quicktype.$className', level: level);
    }
  }
}
