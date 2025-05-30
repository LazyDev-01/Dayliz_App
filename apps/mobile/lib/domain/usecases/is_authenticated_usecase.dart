import '../repositories/auth_repository.dart';

/// Use case to check if a user is authenticated
class IsAuthenticatedUseCase {
  final AuthRepository repository;

  IsAuthenticatedUseCase(this.repository);

  /// Execute the use case
  /// Returns a [bool] indicating if the user is authenticated
  Future<bool> call() {
    return repository.isAuthenticated();
  }
} 