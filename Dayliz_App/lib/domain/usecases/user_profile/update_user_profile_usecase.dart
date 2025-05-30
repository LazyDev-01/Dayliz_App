import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_profile.dart';
import '../../repositories/user_profile_repository.dart';

/// Use case for updating a user profile
class UpdateUserProfileUseCase implements UseCase<UserProfile, UpdateUserProfileParams> {
  final UserProfileRepository repository;

  UpdateUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(UpdateUserProfileParams params) async {
    return await repository.updateUserProfile(params.profile);
  }
}

/// Parameters for [UpdateUserProfileUseCase]
class UpdateUserProfileParams extends Equatable {
  final UserProfile profile;

  const UpdateUserProfileParams({required this.profile});

  @override
  List<Object?> get props => [profile];
} 