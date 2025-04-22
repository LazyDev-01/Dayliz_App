/// Base exception for all app exceptions
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'AppException: $message (Status Code: $statusCode)';
}

/// Server exception for API errors
class ServerException extends AppException {
  ServerException({
    required String message,
    int? statusCode,
    dynamic data,
  }) : super(
          message: message,
          statusCode: statusCode,
          data: data,
        );
}

/// Cache exception for local storage errors
class CacheException extends AppException {
  CacheException({
    required String message,
    dynamic data,
  }) : super(
          message: message,
          data: data,
        );
}

/// Network exception for connectivity issues
class NetworkException extends AppException {
  NetworkException({
    String message = 'No internet connection',
  }) : super(
          message: message,
        );
}

/// Authentication exception for auth errors
class AuthException extends AppException {
  AuthException({
    required String message,
    int? statusCode,
    dynamic data,
  }) : super(
          message: message,
          statusCode: statusCode,
          data: data,
        );
}

/// Not found exception for resource not found errors
class NotFoundException extends AppException {
  NotFoundException({
    required String message,
  }) : super(
          message: message,
        );
}

/// Unauthorized exception for authentication token issues
class UnauthorizedException extends AppException {
  UnauthorizedException({
    required String message,
  }) : super(
          message: message,
        );
}

/// Validation exception for form validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required String message,
    this.fieldErrors,
  }) : super(
          message: message,
          data: fieldErrors,
        );
}

/// Permission exception for permission-related issues
class PermissionException extends AppException {
  PermissionException({
    required String message,
  }) : super(
          message: message,
        );
} 