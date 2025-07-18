import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failures.dart';
import 'unified_error_system.dart';

/// Global Error Handler for the entire Dayliz App
/// Handles uncaught exceptions, API errors, and provides centralized error logging
class GlobalErrorHandler {
  static GlobalErrorHandler? _instance;
  static GlobalErrorHandler get instance => _instance ??= GlobalErrorHandler._();
  
  GlobalErrorHandler._();
  
  /// Initialize global error handling
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      instance._handleFlutterError(details);
    };
    
    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      instance._handleAsyncError(error, stack);
      return true;
    };
    
    // Note: Supabase error handling will be initialized after Supabase setup
    
    developer.log('🛡️ Global Error Handler initialized');
  }

  /// Initialize Supabase-specific error handling (call after Supabase setup)
  static void initializeSupabaseErrorHandling() {
    try {
      // Handle Supabase auth state changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedOut) {
          instance._handleSessionExpiry();
        }
      });

      developer.log('🛡️ Supabase error handling initialized');
    } catch (e) {
      developer.log('⚠️ Failed to initialize Supabase error handling: $e');
    }
  }
  
  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    // Log error for debugging
    developer.log(
      '🔴 Flutter Error: ${details.exception}',
      name: 'GlobalErrorHandler',
      error: details.exception,
      stackTrace: details.stack,
    );
    
    // In debug mode, show the red screen
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      // In release mode, log silently and continue
      _logErrorToAnalytics(
        error: details.exception,
        stackTrace: details.stack,
        context: 'Flutter Framework Error',
      );
    }
  }
  
  /// Handle async errors
  void _handleAsyncError(Object error, StackTrace stackTrace) {
    developer.log(
      '🔴 Async Error: $error',
      name: 'GlobalErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );
    
    _logErrorToAnalytics(
      error: error,
      stackTrace: stackTrace,
      context: 'Async Error',
    );
  }
  
  /// Handle session expiry
  void _handleSessionExpiry() {
    developer.log('🔐 Session expired - user signed out');
    
    // Navigate to login screen
    // This would be implemented based on your navigation system
    // For now, just log the event
  }
  
  /// Log error to analytics service
  void _logErrorToAnalytics({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    // TODO: Implement analytics logging
    // This could be Firebase Crashlytics, Sentry, or custom analytics
    
    final errorData = {
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      ...?additionalData,
    };
    
    developer.log(
      '📊 Error logged to analytics: $errorData',
      name: 'GlobalErrorHandler',
    );
  }
  
  /// Handle API errors and convert to user-friendly failures
  static Failure handleApiError(dynamic error) {
    developer.log('🌐 API Error: $error', name: 'GlobalErrorHandler');
    
    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    } else if (error is AuthException) {
      return _handleAuthError(error);
    } else if (error is StorageException) {
      return _handleStorageError(error);
    } else {
      return _handleGenericError(error);
    }
  }
  
  /// Handle Supabase Postgrest errors
  static Failure _handlePostgrestError(PostgrestException error) {
    final message = error.message;
    final code = error.code;
    
    // Business logic errors
    if (message.contains('insufficient_stock')) {
      return BusinessFailure(message: 'Some items in your cart are out of stock');
    }
    
    if (message.contains('delivery_area')) {
      return BusinessFailure(message: 'Delivery not available in your area');
    }
    
    if (message.contains('minimum_order')) {
      return BusinessFailure(message: 'Minimum order amount is ₹99');
    }
    
    // Database constraint errors
    if (message.contains('duplicate key') || message.contains('already exists')) {
      return ValidationFailure(message: 'This item already exists');
    }
    
    if (message.contains('foreign key') || message.contains('violates')) {
      return ValidationFailure(message: 'Invalid data provided');
    }
    
    // Permission errors
    if (code == '42501' || message.contains('permission denied')) {
      return AuthFailure(message: 'You don\'t have permission to perform this action');
    }
    
    // Not found errors
    if (code == '42P01' || message.contains('does not exist')) {
      return NotFoundFailure(message: 'Requested resource not found');
    }
    
    // Default server error
    return ServerFailure(message: 'Server error occurred. Please try again');
  }
  
  /// Handle Supabase Auth errors
  static Failure _handleAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    
    if (message.contains('invalid login credentials')) {
      return AuthFailure(message: 'Invalid email or password');
    }
    
    if (message.contains('email not confirmed')) {
      return AuthFailure(message: 'Please verify your email address');
    }
    
    if (message.contains('user already registered')) {
      return AuthFailure(message: 'An account with this email already exists');
    }
    
    if (message.contains('password')) {
      return AuthFailure(message: 'Password does not meet requirements');
    }
    
    if (message.contains('rate limit')) {
      return AuthFailure(message: 'Too many attempts. Please try again later');
    }
    
    return AuthFailure(message: error.message);
  }
  
  /// Handle Supabase Storage errors
  static Failure _handleStorageError(StorageException error) {
    final message = error.message.toLowerCase();
    
    if (message.contains('file too large')) {
      return ValidationFailure(message: 'File size is too large. Maximum 5MB allowed');
    }
    
    if (message.contains('invalid file type')) {
      return ValidationFailure(message: 'Invalid file type. Only images are allowed');
    }
    
    if (message.contains('not found')) {
      return NotFoundFailure(message: 'File not found');
    }
    
    return ServerFailure(message: 'File upload failed. Please try again');
  }
  
  /// Handle generic errors
  static Failure _handleGenericError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return const NetworkFailure(message: 'No internet connection');
    }
    
    // Timeout errors
    if (errorString.contains('timeout')) {
      return const ServerFailure(message: 'Request timed out. Please try again');
    }
    
    // Format errors
    if (errorString.contains('format') || errorString.contains('json')) {
      return const ServerFailure(message: 'Invalid data format received');
    }
    
    return ServerFailure(message: 'An unexpected error occurred');
  }
  
  /// Show error to user using unified error system
  static void showErrorToUser(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final errorInfo = UnifiedErrorSystem.mapToUserFriendly(error);
    
    // Show as SnackBar for non-critical errors
    if (errorInfo.type == ErrorType.validation ||
        errorInfo.type == ErrorType.business) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(errorInfo.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorInfo.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      // Show as dialog for critical errors
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: UniversalErrorWidget(
            errorInfo: errorInfo,
            onRetry: onRetry != null
                ? () {
                    Navigator.of(context).pop();
                    onRetry();
                  }
                : () => Navigator.of(context).pop(),
            isCompact: true,
          ),
        ),
      );
    }
  }
}

/// Business logic failure
class BusinessFailure extends Failure {
  const BusinessFailure({String message = 'Business logic error'}) : super(message);
}
