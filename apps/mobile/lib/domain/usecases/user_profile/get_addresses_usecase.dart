import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/address.dart';
import '../../repositories/user_profile_repository.dart';

class GetAddressesUseCase implements UseCase<List<Address>, GetAddressesParams> {
  final UserProfileRepository repository;

  GetAddressesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Address>>> call(GetAddressesParams params) async {
    return await repository.getAddresses(params.userId);
  }
}

class GetAddressesParams extends Equatable {
  final String userId;

  const GetAddressesParams({required this.userId});

  @override
  List<Object> get props => [userId];
} 