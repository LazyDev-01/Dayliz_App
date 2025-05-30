import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to logout a user
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  /// Execute the use case
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> call() {
    return repository.logout();
  }
} 