import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Use case for changing password for authenticated user
class ChangePasswordUseCase implements UseCase<bool, ChangePasswordParams> {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ChangePasswordParams params) async {
    return await repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}

/// Parameters for change password use case
class ChangePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}
