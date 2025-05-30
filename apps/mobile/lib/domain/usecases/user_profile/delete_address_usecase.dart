import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/user_profile_repository.dart';

class DeleteAddressUseCase implements UseCase<bool, DeleteAddressParams> {
  final UserProfileRepository repository;

  DeleteAddressUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteAddressParams params) {
    return repository.deleteAddress(
      params.userId,
      params.addressId,
    );
  }
}

class DeleteAddressParams extends Equatable {
  final String userId;
  final String addressId;

  const DeleteAddressParams({
    required this.userId,
    required this.addressId,
  });

  @override
  List<Object?> get props => [userId, addressId];
} 