import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../repositories/auth_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to send a password reset email
class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> call(ForgotPasswordParams params) {
    return repository.forgotPassword(
      email: params.email,
    );
  }
}

/// Parameters for the ForgotPasswordUseCase
class ForgotPasswordParams extends Equatable {
  final String email;

  const ForgotPasswordParams({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
} 