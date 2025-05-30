import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/user_profile_repository.dart';

/// Use case for uploading a profile image
class UploadProfileImageUseCase implements UseCase<String, UploadProfileImageParams> {
  final UserProfileRepository repository;

  UploadProfileImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(UploadProfileImageParams params) async {
    // Convert the image path to a File
    File imageFile = File(params.imagePath);
    return await repository.updateProfileImage(params.userId, imageFile);
  }
}

/// Parameters for [UploadProfileImageUseCase]
class UploadProfileImageParams extends Equatable {
  final String userId;
  final String imagePath;

  const UploadProfileImageParams({
    required this.userId,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [userId, imagePath];
} 