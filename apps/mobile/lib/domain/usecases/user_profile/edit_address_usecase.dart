import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/address.dart';
import '../../repositories/user_profile_repository.dart';

class EditAddressUseCase implements UseCase<Address, EditAddressParams> {
  final UserProfileRepository repository;

  EditAddressUseCase(this.repository);

  @override
  Future<Either<Failure, Address>> call(EditAddressParams params) async {
    return await repository.updateAddress(
      params.userId,
      params.updatedAddress,
    );
  }
}

class EditAddressParams extends Equatable {
  final String userId;
  final String addressId;
  final Address updatedAddress;

  const EditAddressParams({
    required this.userId,
    required this.addressId,
    required this.updatedAddress,
  });

  @override
  List<Object> get props => [userId, addressId, updatedAddress];
} 