import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/address.dart';
import '../../repositories/user_profile_repository.dart';

class UpdateAddressUseCase implements UseCase<Address, UpdateAddressParams> {
  final UserProfileRepository repository;

  UpdateAddressUseCase(this.repository);

  @override
  Future<Either<Failure, Address>> call(UpdateAddressParams params) async {
    return await repository.updateAddress(
      params.userId,
      params.address,
    );
  }
}

class UpdateAddressParams extends Equatable {
  final String userId;
  final Address address;

  const UpdateAddressParams({
    required this.userId,
    required this.address,
  });

  @override
  List<Object> get props => [userId, address];
} 