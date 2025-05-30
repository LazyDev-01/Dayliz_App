import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/address.dart';
import '../../repositories/user_profile_repository.dart';

class GetUserAddressesUseCase implements UseCase<List<Address>, GetUserAddressesParams> {
  final UserProfileRepository repository;

  GetUserAddressesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Address>>> call(GetUserAddressesParams params) {
    return repository.getUserAddresses(params.userId);
  }
}

class GetUserAddressesParams extends Equatable {
  final String userId;

  const GetUserAddressesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
} 