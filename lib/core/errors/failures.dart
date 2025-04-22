import 'package:equatable/equatable.dart';

/// Base failure class for all failure types
abstract class Failure extends Equatable {
  /// Message describing the failure
  final String message;
  
  /// Creates a new failure with a message
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Server failure when API requests fail
class ServerFailure extends Failure {
  const ServerFailure({String message = 'Server error occurred'}) : super(message);
}

/// Network failure when device is offline
class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network connection error'}) : super(message);
}

/// Cache failure when local data operations fail
class CacheFailure extends Failure {
  const CacheFailure({String message = 'Cache error occurred'}) : super(message);
}

/// Auth failure for authentication errors
class AuthFailure extends Failure {
  const AuthFailure({String message = 'Authentication error'}) : super(message);
}

/// Not found failure for resource not found errors
class NotFoundFailure extends Failure {
  const NotFoundFailure({String message = 'Resource not found'}) : super(message);
}

/// Validation failure for input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure({String message = 'Validation error'}) : super(message);
}

/// Unimplemented failure for features not implemented yet
class UnimplementedFailure extends Failure {
  const UnimplementedFailure({String message = 'Feature not implemented'}) : super(message);
} 