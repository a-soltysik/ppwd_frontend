import 'dart:developer' as developer;

class Logger {
  Logger._();

  static void d(String message) {
    _log(message, 'DEBUG');
  }

  static void i(String message) {
    _log(message, 'INFO', level: 800);
  }

  static void w(String message) {
    _log(message, 'WARNING', level: 900);
  }

  static void e(String message, {Object? error}) {
    if (error != null) {
      _log('$message Error: $error', 'ERROR', level: 1000);
    } else {
      _log(message, 'ERROR', level: 1000);
    }
  }
  
  static void _log(String message, String tag, {int level = 0}) {
    developer.log('[$tag] $message', level: level);
  }
}
