import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/location_repository.dart';

/// Use case for checking if location setup is completed
class IsLocationSetupCompletedUseCase implements UseCase<bool, NoParams> {
  final LocationRepository repository;

  IsLocationSetupCompletedUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      final isCompleted = repository.isLocationSetupCompleted();
      return Right(isCompleted);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

/// Use case for marking location setup as completed
class MarkLocationSetupCompletedUseCase implements UseCase<void, NoParams> {
  final LocationRepository repository;

  MarkLocationSetupCompletedUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      repository.markLocationSetupCompleted();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

/// Use case for clearing location setup status
class ClearLocationSetupStatusUseCase implements UseCase<void, NoParams> {
  final LocationRepository repository;

  ClearLocationSetupStatusUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      repository.clearLocationSetupStatus();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
