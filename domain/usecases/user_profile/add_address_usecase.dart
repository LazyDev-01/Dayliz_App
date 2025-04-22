import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/address.dart';
import '../../repositories/user_profile_repository.dart';

class AddAddressUseCase implements UseCase<Address, AddAddressParams> {
  final UserProfileRepository repository;

  AddAddressUseCase(this.repository);

  @override
  Future<Either<Failure, Address>> call(AddAddressParams params) async {
    return await repository.addAddress(
      params.userId,
      params.address,
    );
  }
}

class AddAddressParams extends Equatable {
  final String userId;
  final Address address;

  const AddAddressParams({
    required this.userId,
    required this.address,
  });

  @override
  List<Object> get props => [userId, address];
} 