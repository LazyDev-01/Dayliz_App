/// Core exception classes for the Dayliz App
/// 
/// This file defines custom exceptions used throughout the application
/// for better error handling and debugging.

/// Base exception class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for cart-related local storage operations
class CartLocalException extends AppException {
  const CartLocalException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'CartLocalException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for network-related operations
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'NetworkException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for server-related operations
class ServerException extends AppException {
  const ServerException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'ServerException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for cache-related operations
class CacheException extends AppException {
  const CacheException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'CacheException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for authentication-related operations
class AuthException extends AppException {
  const AuthException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for validation-related operations
class ValidationException extends AppException {
  const ValidationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'ValidationException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for location-related operations
class LocationException extends AppException {
  const LocationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'LocationException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for payment-related operations
class PaymentException extends AppException {
  const PaymentException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'PaymentException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for order-related operations
class OrderException extends AppException {
  const OrderException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'OrderException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for product-related operations
class ProductException extends AppException {
  const ProductException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'ProductException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for wishlist-related operations
class WishlistException extends AppException {
  const WishlistException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'WishlistException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for search-related operations
class SearchException extends AppException {
  const SearchException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'SearchException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for category-related operations
class CategoryException extends AppException {
  const CategoryException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'CategoryException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for not found operations
class NotFoundException extends AppException {
  const NotFoundException({required String message, String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'NotFoundException: $message${code != null ? ' (Code: $code)' : ''}';
}
