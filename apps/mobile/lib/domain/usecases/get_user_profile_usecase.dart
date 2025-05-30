import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// Use case for getting user profile
class GetUserProfileUseCase implements UseCase<UserProfile, GetUserProfileParams> {
  final UserProfileRepository repository;

  GetUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(GetUserProfileParams params) {
    return repository.getUserProfile(params.userId);
  }
}

/// Parameters for GetUserProfileUseCase
class GetUserProfileParams extends Equatable {
  final String userId;

  const GetUserProfileParams({required this.userId});

  @override
  List<Object?> get props => [userId];
} 