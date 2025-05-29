import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Use case for checking if an email already exists in the system
class CheckEmailExistsUseCase implements UseCase<bool, CheckEmailExistsParams> {
  final AuthRepository repository;

  CheckEmailExistsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckEmailExistsParams params) async {
    return await repository.checkEmailExists(email: params.email);
  }
}

/// Parameters for the CheckEmailExistsUseCase
class CheckEmailExistsParams extends Equatable {
  final String email;

  const CheckEmailExistsParams({required this.email});

  @override
  List<Object> get props => [email];
}
