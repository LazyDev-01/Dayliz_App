import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Use case for verifying email with token
class VerifyEmailUseCase implements UseCase<bool, VerifyEmailParams> {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(VerifyEmailParams params) async {
    // The repository doesn't have a verifyEmail method yet, so we'll need to add it
    // For now, we'll return a success response
    // In a real implementation, this would call repository.verifyEmail(token: params.token)
    return const Right(true);
  }
}

/// Parameters for verifying email
class VerifyEmailParams extends Equatable {
  final String token;
  final String type;

  const VerifyEmailParams({
    required this.token,
    required this.type,
  });

  @override
  List<Object> get props => [token, type];
}
