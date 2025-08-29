import 'package:flutter/foundation.dart';

/// Production-ready logging service that conditionally logs based on build mode
/// Replaces debugPrint statements for production builds
class ProductionLogger {
  static const String _tag = 'DaylizApp';

  /// Log levels for different types of messages
  enum LogLevel {
    debug,
    info,
    warning,
    error,
  }

  /// Log a debug message (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, tag: tag);
    }
  }

  /// Log an info message (only in debug mode)
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      _log(LogLevel.info, message, tag: tag);
    }
  }

  /// Log a warning message (only in debug mode)
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      _log(LogLevel.warning, message, tag: tag);
    }
  }

  /// Log an error message (always logged, even in production for crash reporting)
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logTag = tag ?? _tag;
    final levelStr = level.name.toUpperCase();
    
    final logMessage = '[$timestamp] [$levelStr] [$logTag] $message';
    
    // In debug mode, use debugPrint for console output
    if (kDebugMode) {
      debugPrint(logMessage);
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    } else if (level == LogLevel.error) {
      // In production, only log errors (for crash reporting integration)
      // This can be extended to integrate with Firebase Crashlytics or other services
      debugPrint(logMessage);
      if (error != null) {
        debugPrint('Error: $error');
      }
    }
  }

  /// Log authentication events
  static void auth(String message) {
    debug(message, tag: 'Auth');
  }

  /// Log cart events
  static void cart(String message) {
    debug(message, tag: 'Cart');
  }

  /// Log location events
  static void location(String message) {
    debug(message, tag: 'Location');
  }

  /// Log payment events
  static void payment(String message) {
    debug(message, tag: 'Payment');
  }

  /// Log network events
  static void network(String message) {
    debug(message, tag: 'Network');
  }

  /// Log product events
  static void product(String message) {
    debug(message, tag: 'Product');
  }
}
