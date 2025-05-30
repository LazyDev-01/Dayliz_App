import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/user_profile_repository.dart';

/// Updates a user's profile image
class UpdateProfileImageUseCase implements UseCase<String, UpdateProfileImageParams> {
  final UserProfileRepository repository;

  UpdateProfileImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(UpdateProfileImageParams params) {
    return repository.updateProfileImage(params.userId, params.imageFile);
  }
}

/// Parameters for [UpdateProfileImageUseCase]
class UpdateProfileImageParams {
  final String userId;
  final File imageFile;

  UpdateProfileImageParams({
    required this.userId,
    required this.imageFile,
  });
} 