import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../errors/failures.dart';
import '../config/network_config.dart';

/// Comprehensive error logging service for production monitoring
/// Integrates with Firebase Crashlytics and provides structured logging
class ErrorLoggingService {
  static ErrorLoggingService? _instance;
  static ErrorLoggingService get instance => _instance ??= ErrorLoggingService._();
  
  ErrorLoggingService._();
  
  bool _isInitialized = false;
  FirebaseCrashlytics? _crashlytics;
  
  /// Initialize the error logging service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Set up automatic crash reporting
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics?.recordFlutterFatalError(details);
        developer.log(
          '🔴 Flutter Fatal Error: ${details.exception}',
          name: 'ErrorLoggingService',
          error: details.exception,
          stackTrace: details.stack,
        );
      };
      
      // Handle async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics?.recordError(error, stack, fatal: true);
        developer.log(
          '🔴 Async Error: $error',
          name: 'ErrorLoggingService',
          error: error,
          stackTrace: stack,
        );
        return true;
      };
      
      _isInitialized = true;
      developer.log('✅ Error logging service initialized');
      
    } catch (e) {
      developer.log('❌ Failed to initialize error logging: $e');
      // Continue without crashlytics if initialization fails
      _isInitialized = true;
    }
  }
  
  /// Log a network error with context
  void logNetworkError({
    required dynamic error,
    required String operation,
    String? userId,
    Map<String, dynamic>? additionalData,
    bool isFatal = false,
  }) {
    final errorData = {
      'error_type': 'network',
      'operation': operation,
      'error_message': error.toString(),
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      ...?additionalData,
    };
    
    // Log to console for debugging
    developer.log(
      '🌐 Network Error in $operation: $error',
      name: 'NetworkError',
      error: error,
    );
    
    // Log to Crashlytics
    _crashlytics?.recordError(
      error,
      StackTrace.current,
      fatal: isFatal,
      information: [
        DiagnosticsProperty('operation', operation),
        DiagnosticsProperty('errorData', errorData),
      ],
    );
    
    // Set custom keys for better filtering
    _crashlytics?.setCustomKey('last_network_operation', operation);
    _crashlytics?.setCustomKey('last_error_type', 'network');
  }
  
  /// Log a repository error
  void logRepositoryError({
    required dynamic error,
    required String repository,
    required String method,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) {
    final errorData = {
      'error_type': 'repository',
      'repository': repository,
      'method': method,
      'error_message': error.toString(),
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };
    
    developer.log(
      '🗄️ Repository Error in $repository.$method: $error',
      name: 'RepositoryError',
      error: error,
    );
    
    _crashlytics?.recordError(
      error,
      StackTrace.current,
      information: [
        DiagnosticsProperty('repository', repository),
        DiagnosticsProperty('method', method),
        DiagnosticsProperty('errorData', errorData),
      ],
    );
    
    _crashlytics?.setCustomKey('last_repository', repository);
    _crashlytics?.setCustomKey('last_repository_method', method);
  }
  
  /// Log a UI error
  void logUIError({
    required dynamic error,
    required String screen,
    required String widget,
    String? userId,
    String? userAction,
    Map<String, dynamic>? additionalData,
  }) {
    final errorData = {
      'error_type': 'ui',
      'screen': screen,
      'widget': widget,
      'user_action': userAction,
      'error_message': error.toString(),
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };
    
    developer.log(
      '🎨 UI Error in $screen.$widget: $error',
      name: 'UIError',
      error: error,
    );
    
    _crashlytics?.recordError(
      error,
      StackTrace.current,
      information: [
        DiagnosticsProperty('screen', screen),
        DiagnosticsProperty('widget', widget),
        DiagnosticsProperty('userAction', userAction),
        DiagnosticsProperty('errorData', errorData),
      ],
    );
    
    _crashlytics?.setCustomKey('last_screen', screen);
    _crashlytics?.setCustomKey('last_widget', widget);
  }
  
  /// Log a business logic error
  void logBusinessError({
    required Failure failure,
    required String operation,
    String? userId,
    Map<String, dynamic>? context,
  }) {
    final errorData = {
      'error_type': 'business',
      'failure_type': failure.runtimeType.toString(),
      'operation': operation,
      'error_message': failure.message,
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    };
    
    developer.log(
      '💼 Business Error in $operation: ${failure.message}',
      name: 'BusinessError',
    );
    
    // Only log to Crashlytics if it's a critical business error
    if (failure is ServerFailure || failure is NetworkFailure) {
      _crashlytics?.recordError(
        failure,
        StackTrace.current,
        information: [
          DiagnosticsProperty('operation', operation),
          DiagnosticsProperty('failureType', failure.runtimeType.toString()),
          DiagnosticsProperty('errorData', errorData),
        ],
      );
    }
    
    _crashlytics?.setCustomKey('last_business_operation', operation);
    _crashlytics?.setCustomKey('last_failure_type', failure.runtimeType.toString());
  }
  
  /// Log performance issues
  void logPerformanceIssue({
    required String operation,
    required Duration duration,
    Duration? threshold,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) {
    final thresholdMs = threshold?.inMilliseconds ?? 5000; // Default 5 second threshold
    
    if (duration.inMilliseconds > thresholdMs) {
      final errorData = {
        'error_type': 'performance',
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'threshold_ms': thresholdMs,
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalData,
      };
      
      developer.log(
        '⚡ Performance Issue in $operation: ${duration.inMilliseconds}ms (threshold: ${thresholdMs}ms)',
        name: 'PerformanceIssue',
      );
      
      _crashlytics?.recordError(
        'Performance threshold exceeded',
        StackTrace.current,
        information: [
          DiagnosticsProperty('operation', operation),
          DiagnosticsProperty('duration', duration.inMilliseconds),
          DiagnosticsProperty('threshold', thresholdMs),
          DiagnosticsProperty('errorData', errorData),
        ],
      );
      
      _crashlytics?.setCustomKey('last_slow_operation', operation);
      _crashlytics?.setCustomKey('last_operation_duration', duration.inMilliseconds);
    }
  }
  
  /// Set user context for error tracking
  void setUserContext({
    required String userId,
    String? email,
    Map<String, dynamic>? additionalData,
  }) {
    _crashlytics?.setUserIdentifier(userId);
    
    if (email != null) {
      _crashlytics?.setCustomKey('user_email', email);
    }
    
    additionalData?.forEach((key, value) {
      _crashlytics?.setCustomKey('user_$key', value.toString());
    });
    
    developer.log('👤 User context set: $userId');
  }
  
  /// Clear user context (on logout)
  void clearUserContext() {
    _crashlytics?.setUserIdentifier('');
    _crashlytics?.setCustomKey('user_email', '');
    
    developer.log('👤 User context cleared');
  }
  
  /// Log custom event for analytics
  void logCustomEvent({
    required String event,
    Map<String, dynamic>? parameters,
  }) {
    developer.log('📊 Custom Event: $event', name: 'CustomEvent');
    
    _crashlytics?.log('Custom Event: $event');
    
    parameters?.forEach((key, value) {
      _crashlytics?.setCustomKey('event_$key', value.toString());
    });
  }
  
  /// Force send pending crash reports (useful for testing)
  Future<void> sendPendingReports() async {
    try {
      await _crashlytics?.sendUnsentReports();
      developer.log('📤 Pending crash reports sent');
    } catch (e) {
      developer.log('❌ Failed to send pending reports: $e');
    }
  }
  
  /// Check if crash reporting is enabled
  bool get isCrashReportingEnabled => _crashlytics != null && _isInitialized;
  
  /// Enable/disable crash reporting
  Future<void> setCrashReportingEnabled(bool enabled) async {
    try {
      await _crashlytics?.setCrashlyticsCollectionEnabled(enabled);
      developer.log('🔧 Crash reporting ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      developer.log('❌ Failed to set crash reporting: $e');
    }
  }
}
