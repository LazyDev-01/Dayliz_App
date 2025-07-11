import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for network connectivity detection and error classification
class NetworkService {
  static const Duration _timeoutDuration = Duration(seconds: 10);

  /// Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      // Check connectivity status first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Verify actual internet access by pinging a reliable server
      final result = await InternetAddress.lookup('google.com')
          .timeout(_timeoutDuration);
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('NetworkService: Internet check failed: $e');
      return false;
    }
  }

  /// Classify error type for better user messaging
  static NetworkErrorType classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network connectivity errors
    if (errorString.contains('socketexception') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('connection timed out') ||
        errorString.contains('connection refused') ||
        errorString.contains('network error') ||
        errorString.contains('timeout')) {
      return NetworkErrorType.connectivity;
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504') ||
        errorString.contains('server error') ||
        errorString.contains('internal server error')) {
      return NetworkErrorType.server;
    }

    // Authentication errors
    if (errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('authentication')) {
      return NetworkErrorType.authentication;
    }

    // Business logic errors
    if (errorString.contains('product not found') ||
        errorString.contains('out of stock') ||
        errorString.contains('insufficient stock') ||
        errorString.contains('delivery_address_id') ||
        errorString.contains('minimum order') ||
        errorString.contains('maximum order') ||
        errorString.contains('cod order') ||
        errorString.contains('payment method')) {
      return NetworkErrorType.business;
    }

    // Default to connectivity if unsure
    return NetworkErrorType.connectivity;
  }

  /// Get user-friendly error message based on error type
  static String getErrorMessage(NetworkErrorType errorType, {String? customMessage}) {
    switch (errorType) {
      case NetworkErrorType.connectivity:
        return customMessage ?? 
               'Poor network connection. Please check your internet and try again.';
      
      case NetworkErrorType.server:
        return customMessage ?? 
               'Our servers are temporarily busy. Please try again in a moment.';
      
      case NetworkErrorType.authentication:
        return customMessage ?? 
               'Please login again to continue.';
      
      case NetworkErrorType.business:
        return customMessage ?? 
               'Please check your order details and try again.';
      
      default:
        return customMessage ?? 
               'Something went wrong. Please try again.';
    }
  }

  /// Check if error should trigger offline mode
  static bool shouldUseOfflineMode(dynamic error) {
    final errorType = classifyError(error);
    return errorType == NetworkErrorType.connectivity;
  }

  /// Get retry strategy based on error type
  static RetryStrategy getRetryStrategy(NetworkErrorType errorType) {
    switch (errorType) {
      case NetworkErrorType.connectivity:
        return RetryStrategy(
          maxAttempts: 3,
          delayBetweenAttempts: Duration(seconds: 2),
          shouldRetry: true,
        );
      
      case NetworkErrorType.server:
        return RetryStrategy(
          maxAttempts: 2,
          delayBetweenAttempts: Duration(seconds: 5),
          shouldRetry: true,
        );
      
      case NetworkErrorType.authentication:
      case NetworkErrorType.business:
        return RetryStrategy(
          maxAttempts: 1,
          delayBetweenAttempts: Duration.zero,
          shouldRetry: false,
        );
      
      default:
        return RetryStrategy(
          maxAttempts: 1,
          delayBetweenAttempts: Duration.zero,
          shouldRetry: false,
        );
    }
  }

  /// Listen to connectivity changes
  static Stream<ConnectivityResult> get connectivityStream =>
      Connectivity().onConnectivityChanged;
}

/// Types of network errors for classification
enum NetworkErrorType {
  connectivity,    // Network/internet issues
  server,         // Server-side problems
  authentication, // Auth/permission issues
  business,       // Business logic errors
}

/// Retry strategy configuration
class RetryStrategy {
  final int maxAttempts;
  final Duration delayBetweenAttempts;
  final bool shouldRetry;

  const RetryStrategy({
    required this.maxAttempts,
    required this.delayBetweenAttempts,
    required this.shouldRetry,
  });
}
