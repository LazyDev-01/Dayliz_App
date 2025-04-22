import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to get the current authenticated user
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  /// Execute the use case
  /// Returns a [Either] with a [Failure] or a [User] entity
  Future<Either<Failure, User>> call() {
    return repository.getCurrentUser();
  }
} 