import 'package:dartz/dartz.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/location_repository.dart';

/// Use case for requesting location permission from user
class RequestLocationPermissionUseCase implements UseCase<PermissionStatus, NoParams> {
  final LocationRepository repository;

  RequestLocationPermissionUseCase(this.repository);

  @override
  Future<Either<Failure, PermissionStatus>> call(NoParams params) async {
    return await repository.requestLocationPermission();
  }
}

/// Use case for checking current location permission status
class CheckLocationPermissionUseCase implements UseCase<PermissionStatus, NoParams> {
  final LocationRepository repository;

  CheckLocationPermissionUseCase(this.repository);

  @override
  Future<Either<Failure, PermissionStatus>> call(NoParams params) async {
    return await repository.checkLocationPermission();
  }
}

/// Use case for checking if location services are enabled
class IsLocationServiceEnabledUseCase implements UseCase<bool, NoParams> {
  final LocationRepository repository;

  IsLocationServiceEnabledUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.isLocationServiceEnabled();
  }
}
