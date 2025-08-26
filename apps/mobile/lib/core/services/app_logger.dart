import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Application-wide logging service
/// Provides structured logging with different levels and proper formatting
class AppLogger {
  static AppLogger? _instance;
  static AppLogger get instance => _instance ??= AppLogger._();
  
  late final Logger _logger;
  
  AppLogger._() {
    _logger = Logger(
      printer: _getLoggerPrinter(),
      level: _getLogLevel(),
      output: _getLogOutput(),
    );
  }

  /// Get appropriate printer based on environment
  LogPrinter _getLoggerPrinter() {
    if (kDebugMode) {
      return PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      );
    } else {
      return SimplePrinter();
    }
  }

  /// Get log level based on environment
  Level _getLogLevel() {
    if (kDebugMode) {
      return Level.debug;
    } else if (kProfileMode) {
      return Level.info;
    } else {
      return Level.warning;
    }
  }

  /// Get log output based on environment
  LogOutput _getLogOutput() {
    if (kDebugMode) {
      return ConsoleOutput();
    } else {
      // In production, you might want to use a file output or remote logging
      return ConsoleOutput();
    }
  }

  /// Log debug messages (only in debug mode)
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info messages
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal/critical errors
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log service-specific messages with context
  void service(String serviceName, String message, {Level level = Level.info}) {
    final contextMessage = '[$serviceName] $message';
    switch (level) {
      case Level.debug:
        debug(contextMessage);
        break;
      case Level.info:
        info(contextMessage);
        break;
      case Level.warning:
        warning(contextMessage);
        break;
      case Level.error:
        error(contextMessage);
        break;
      case Level.fatal:
        fatal(contextMessage);
        break;
      default:
        info(contextMessage);
    }
  }

  /// Log API calls and responses
  void api(String method, String endpoint, {
    int? statusCode,
    String? error,
    Duration? duration,
  }) {
    final message = StringBuffer('API $method $endpoint');
    if (statusCode != null) {
      message.write(' - Status: $statusCode');
    }
    if (duration != null) {
      message.write(' - Duration: ${duration.inMilliseconds}ms');
    }
    
    if (error != null) {
      this.error('$message - Error: $error');
    } else if (statusCode != null && statusCode >= 400) {
      warning(message.toString());
    } else {
      info(message.toString());
    }
  }

  /// Log performance metrics
  void performance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    final message = 'Performance: $operation took ${duration.inMilliseconds}ms';
    if (metadata != null && metadata.isNotEmpty) {
      info('$message - Metadata: $metadata');
    } else {
      info(message);
    }
  }

  /// Log user actions for analytics
  void userAction(String action, {Map<String, dynamic>? properties}) {
    final message = 'User Action: $action';
    if (properties != null && properties.isNotEmpty) {
      info('$message - Properties: $properties');
    } else {
      info(message);
    }
  }

  /// Log navigation events
  void navigation(String from, String to, {Map<String, dynamic>? parameters}) {
    final message = 'Navigation: $from -> $to';
    if (parameters != null && parameters.isNotEmpty) {
      info('$message - Parameters: $parameters');
    } else {
      info(message);
    }
  }

  /// Log payment-related events (with sensitive data filtering)
  void payment(String event, {
    String? orderId,
    String? paymentId,
    String? status,
    double? amount,
    String? error,
  }) {
    final message = StringBuffer('Payment: $event');
    if (orderId != null) message.write(' - Order: $orderId');
    if (paymentId != null) {
      // Mask payment ID for security
      final maskedId = paymentId.length > 8 
          ? '${paymentId.substring(0, 4)}****${paymentId.substring(paymentId.length - 4)}'
          : '****';
      message.write(' - Payment: $maskedId');
    }
    if (status != null) message.write(' - Status: $status');
    if (amount != null) message.write(' - Amount: ₹$amount');
    
    if (error != null) {
      this.error('$message - Error: $error');
    } else {
      info(message.toString());
    }
  }

  /// Log authentication events
  void auth(String event, {String? userId, String? method, String? error}) {
    final message = StringBuffer('Auth: $event');
    if (userId != null) {
      // Mask user ID for privacy
      final maskedId = userId.length > 8 
          ? '${userId.substring(0, 4)}****${userId.substring(userId.length - 4)}'
          : '****';
      message.write(' - User: $maskedId');
    }
    if (method != null) message.write(' - Method: $method');
    
    if (error != null) {
      this.error('$message - Error: $error');
    } else {
      info(message.toString());
    }
  }

  /// Log database operations
  void database(String operation, String table, {
    String? id,
    String? error,
    Duration? duration,
  }) {
    final message = StringBuffer('Database: $operation on $table');
    if (id != null) message.write(' - ID: $id');
    if (duration != null) message.write(' - Duration: ${duration.inMilliseconds}ms');
    
    if (error != null) {
      this.error('$message - Error: $error');
    } else {
      info(message.toString());
    }
  }

  /// Close logger resources
  void close() {
    _logger.close();
  }
}

/// Global logger instance for easy access
final appLogger = AppLogger.instance;

/// Extension for easy logging from any class
extension LoggerExtension on Object {
  void logDebug(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.debug('${runtimeType.toString()}: $message', error, stackTrace);
  }

  void logInfo(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.info('${runtimeType.toString()}: $message', error, stackTrace);
  }

  void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.warning('${runtimeType.toString()}: $message', error, stackTrace);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    appLogger.error('${runtimeType.toString()}: $message', error, stackTrace);
  }
}
