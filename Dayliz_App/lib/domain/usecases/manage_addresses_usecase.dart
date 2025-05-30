import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user_profile.dart';
import '../entities/address.dart';
import '../repositories/user_profile_repository.dart';

/// Get user addresses use case
class GetUserAddressesUseCase implements UseCase<List<Address>, GetUserAddressesParams> {
  final UserProfileRepository repository;

  GetUserAddressesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Address>>> call(GetUserAddressesParams params) {
    return repository.getUserAddresses(params.userId);
  }
}

/// Add address use case
class AddAddressUseCase implements UseCase<Address, AddAddressParams> {
  final UserProfileRepository repository;

  AddAddressUseCase(this.repository);

  @override
  Future<Either<Failure, Address>> call(AddAddressParams params) {
    return repository.addAddress(params.userId, params.address);
  }
}

/// Update address use case
class UpdateAddressUseCase implements UseCase<Address, UpdateAddressParams> {
  final UserProfileRepository repository;

  UpdateAddressUseCase(this.repository);

  @override
  Future<Either<Failure, Address>> call(UpdateAddressParams params) {
    return repository.updateAddress(params.userId, params.address);
  }
}

/// Delete address use case
class DeleteAddressUseCase implements UseCase<bool, DeleteAddressParams> {
  final UserProfileRepository repository;

  DeleteAddressUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteAddressParams params) {
    return repository.deleteAddress(params.userId, params.addressId);
  }
}

/// Set default address use case
class SetDefaultAddressUseCase implements UseCase<bool, SetDefaultAddressParams> {
  final UserProfileRepository repository;

  SetDefaultAddressUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SetDefaultAddressParams params) {
    return repository.setDefaultAddress(params.userId, params.addressId);
  }
}

/// Parameters for GetUserAddressesUseCase
class GetUserAddressesParams extends Equatable {
  final String userId;

  const GetUserAddressesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Parameters for AddAddressUseCase
class AddAddressParams extends Equatable {
  final String userId;
  final Address address;

  const AddAddressParams({required this.userId, required this.address});

  @override
  List<Object?> get props => [userId, address];
}

/// Parameters for UpdateAddressUseCase
class UpdateAddressParams extends Equatable {
  final String userId;
  final Address address;

  const UpdateAddressParams({required this.userId, required this.address});

  @override
  List<Object?> get props => [userId, address];
}

/// Parameters for DeleteAddressUseCase
class DeleteAddressParams extends Equatable {
  final String userId;
  final String addressId;

  const DeleteAddressParams({required this.userId, required this.addressId});

  @override
  List<Object?> get props => [userId, addressId];
}

/// Parameters for SetDefaultAddressUseCase
class SetDefaultAddressParams extends Equatable {
  final String userId;
  final String addressId;

  const SetDefaultAddressParams({required this.userId, required this.addressId});

  @override
  List<Object?> get props => [userId, addressId];
} 