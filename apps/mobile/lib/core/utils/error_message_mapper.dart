import 'dart:io';

/// Utility class to convert technical error messages into user-friendly messages
class ErrorMessageMapper {
  
  /// Maps technical error messages to user-friendly messages
  static String mapErrorToUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network connectivity errors
    if (_isNetworkError(errorString)) {
      return 'Connection problem';
    }
    
    // Server errors
    if (_isServerError(errorString)) {
      return 'Service temporarily unavailable';
    }
    
    // Timeout errors
    if (_isTimeoutError(errorString)) {
      return 'Request timed out';
    }
    
    // Authentication errors
    if (_isAuthError(errorString)) {
      return 'Authentication required';
    }
    
    // Permission errors
    if (_isPermissionError(errorString)) {
      return 'Access denied';
    }
    
    // Data format errors
    if (_isDataFormatError(errorString)) {
      return 'Data format error';
    }
    
    // Storage errors
    if (_isStorageError(errorString)) {
      return 'Storage error';
    }
    
    // Default fallback
    return 'Something went wrong';
  }
  
  /// Gets a user-friendly subtitle for additional context
  static String getErrorSubtitle(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (_isNetworkError(errorString)) {
      return 'Please check your internet connection and try again';
    }
    
    if (_isServerError(errorString)) {
      return 'Our servers are having issues. Please try again in a moment';
    }
    
    if (_isTimeoutError(errorString)) {
      return 'The request took too long. Please try again';
    }
    
    if (_isAuthError(errorString)) {
      return 'Please log in again to continue';
    }
    
    if (_isPermissionError(errorString)) {
      return 'You don\'t have permission to access this resource';
    }
    
    if (_isDataFormatError(errorString)) {
      return 'The data received was in an unexpected format';
    }
    
    if (_isStorageError(errorString)) {
      return 'Unable to save or retrieve data locally';
    }
    
    return 'Please try again or contact support if the problem persists';
  }
  
  /// Determines the appropriate retry text based on error type
  static String getRetryText(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (_isNetworkError(errorString)) {
      return 'Retry';
    }
    
    if (_isServerError(errorString)) {
      return 'Try Again';
    }
    
    if (_isTimeoutError(errorString)) {
      return 'Retry';
    }
    
    if (_isAuthError(errorString)) {
      return 'Log In';
    }
    
    return 'Try Again';
  }
  
  /// Checks if the error is network-related
  static bool _isNetworkError(String errorString) {
    return errorString.contains('socketexception') ||
           errorString.contains('failed host lookup') ||
           errorString.contains('network is unreachable') ||
           errorString.contains('connection refused') ||
           errorString.contains('connection reset') ||
           errorString.contains('no internet') ||
           errorString.contains('clientexception') ||
           errorString.contains('connection error') ||
           errorString.contains('network error');
  }
  
  /// Checks if the error is server-related
  static bool _isServerError(String errorString) {
    return errorString.contains('500') ||
           errorString.contains('502') ||
           errorString.contains('503') ||
           errorString.contains('504') ||
           errorString.contains('internal server error') ||
           errorString.contains('bad gateway') ||
           errorString.contains('service unavailable') ||
           errorString.contains('gateway timeout') ||
           errorString.contains('server error');
  }
  
  /// Checks if the error is timeout-related
  static bool _isTimeoutError(String errorString) {
    return errorString.contains('timeout') ||
           errorString.contains('timed out') ||
           errorString.contains('408') ||
           errorString.contains('request timeout');
  }
  
  /// Checks if the error is authentication-related
  static bool _isAuthError(String errorString) {
    return errorString.contains('401') ||
           errorString.contains('unauthorized') ||
           errorString.contains('authentication') ||
           errorString.contains('invalid token') ||
           errorString.contains('token expired') ||
           errorString.contains('access token');
  }
  
  /// Checks if the error is permission-related
  static bool _isPermissionError(String errorString) {
    return errorString.contains('403') ||
           errorString.contains('forbidden') ||
           errorString.contains('access denied') ||
           errorString.contains('permission denied');
  }
  
  /// Checks if the error is data format-related
  static bool _isDataFormatError(String errorString) {
    return errorString.contains('formatexception') ||
           errorString.contains('json') ||
           errorString.contains('parsing') ||
           errorString.contains('invalid format') ||
           errorString.contains('unexpected character') ||
           errorString.contains('bad response format');
  }
  
  /// Checks if the error is storage-related
  static bool _isStorageError(String errorString) {
    return errorString.contains('storage') ||
           errorString.contains('cache') ||
           errorString.contains('database') ||
           errorString.contains('file system') ||
           errorString.contains('disk') ||
           errorString.contains('sqlite');
  }
}

/// Extension to easily convert errors to user-friendly messages
extension ErrorToUserFriendly on Object {
  String get userFriendlyMessage => ErrorMessageMapper.mapErrorToUserFriendlyMessage(this);
  String get userFriendlySubtitle => ErrorMessageMapper.getErrorSubtitle(this);
  String get retryText => ErrorMessageMapper.getRetryText(this);
}

/// Specific error message mappings for common scenarios
class ContextualErrorMessages {
  
  /// Error messages for categories loading
  static const String categoriesLoadFailed = 'Unable to load categories';
  static const String categoriesLoadSubtitle = 'Please check your connection and try again';
  
  /// Error messages for products loading
  static const String productsLoadFailed = 'Unable to load products';
  static const String productsLoadSubtitle = 'Please check your connection and try again';
  
  /// Error messages for home screen
  static const String homeDataLoadFailed = 'Unable to load content';
  static const String homeDataLoadSubtitle = 'Please check your connection and try again';
  
  /// Error messages for cart operations
  static const String cartLoadFailed = 'Cart unavailable';
  static const String cartLoadSubtitle = 'Unable to load your cart. Please try again';
  
  /// Error messages for orders
  static const String ordersLoadFailed = 'Orders unavailable';
  static const String ordersLoadSubtitle = 'Unable to load your orders. Please try again';
  
  /// Error messages for addresses
  static const String addressesLoadFailed = 'Addresses unavailable';
  static const String addressesLoadSubtitle = 'Unable to load your addresses. Please try again';
  
  /// Error messages for search
  static const String searchFailed = 'Search unavailable';
  static const String searchFailedSubtitle = 'Unable to search right now. Please try again';
}
