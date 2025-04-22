import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/user_profile_repository.dart';

class SetDefaultAddressUseCase implements UseCase<bool, SetDefaultAddressParams> {
  final UserProfileRepository repository;

  SetDefaultAddressUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SetDefaultAddressParams params) async {
    return await repository.setDefaultAddress(
      params.userId,
      params.addressId,
    );
  }
}

class SetDefaultAddressParams extends Equatable {
  final String userId;
  final String addressId;

  const SetDefaultAddressParams({
    required this.userId,
    required this.addressId,
  });

  @override
  List<Object> get props => [userId, addressId];
} 