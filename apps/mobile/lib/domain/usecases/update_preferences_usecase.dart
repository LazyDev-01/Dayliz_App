import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/user_profile_repository.dart';

/// Use case for updating user preferences
class UpdatePreferencesUseCase implements UseCase<Map<String, dynamic>, UpdatePreferencesParams> {
  final UserProfileRepository repository;

  UpdatePreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(UpdatePreferencesParams params) async {
    return await repository.updateUserPreferences(params.userId, params.preferences);
  }
}

/// Parameters for [UpdatePreferencesUseCase]
class UpdatePreferencesParams extends Equatable {
  final String userId;
  final Map<String, dynamic> preferences;

  const UpdatePreferencesParams({
    required this.userId,
    required this.preferences,
  });

  @override
  List<Object?> get props => [userId, preferences];
} 