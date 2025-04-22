import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/user_profile_repository.dart';

/// Updates user preferences
class UpdateUserPreferencesUseCase implements UseCase<Map<String, dynamic>, UpdateUserPreferencesParams> {
  final UserProfileRepository repository;

  UpdateUserPreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(UpdateUserPreferencesParams params) {
    return repository.updateUserPreferences(
      params.userId,
      params.preferences,
    );
  }
}

/// Parameters for [UpdateUserPreferencesUseCase]
class UpdateUserPreferencesParams {
  final String userId;
  final Map<String, dynamic> preferences;

  UpdateUserPreferencesParams({
    required this.userId,
    required this.preferences,
  });
} 