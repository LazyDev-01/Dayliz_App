import 'package:dartz/dartz.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/zone.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/zone_repository.dart';
import '../datasources/location_local_data_source.dart';

/// Implementation of LocationRepository
class LocationRepositoryImpl implements LocationRepository {
  final LocationLocalDataSource localDataSource;
  final ZoneRepository zoneRepository;
  final NetworkInfo networkInfo;

  LocationRepositoryImpl({
    required this.localDataSource,
    required this.zoneRepository,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, bool>> isLocationServiceEnabled() async {
    try {
      final isEnabled = await localDataSource.isLocationServiceEnabled();
      return Right(isEnabled);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PermissionStatus>> checkLocationPermission() async {
    try {
      final permission = await localDataSource.checkLocationPermission();
      return Right(permission);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PermissionStatus>> requestLocationPermission() async {
    try {
      final permission = await localDataSource.requestLocationPermission();
      return Right(permission);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LocationCoordinates>> getCurrentLocation() async {
    try {
      final coordinatesModel = await localDataSource.getCurrentLocation();
      return Right(coordinatesModel.toEntity());
    } on LocationServiceDisabledException catch (e) {
      return Left(LocationFailure(message: e.message));
    } on LocationPermissionDeniedException catch (e) {
      return Left(LocationFailure(message: e.message));
    } on LocationPermissionPermanentlyDeniedException catch (e) {
      return Left(LocationFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ZoneValidationResult>> validateDeliveryZone(
    LocationCoordinates coordinates,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final zoneResult = await zoneRepository.getZoneForLocation(
          coordinates.latitude,
          coordinates.longitude,
        );

        return zoneResult.fold(
          (failure) => Left(failure),
          (zone) {
            if (zone != null) {
              return Right(ZoneValidationResult.valid(
                zone: zone,
                coordinates: coordinates,
              ));
            } else {
              return Right(ZoneValidationResult.invalid(
                errorMessage: 'No delivery zone found for your location',
                coordinates: coordinates,
              ));
            }
          },
        );
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Zone>> getZoneById(String zoneId) async {
    return await zoneRepository.getZoneById(zoneId);
  }

  @override
  bool isLocationSetupCompleted() {
    return localDataSource.isLocationSetupCompleted();
  }

  @override
  void markLocationSetupCompleted() {
    localDataSource.markLocationSetupCompleted();
  }

  @override
  void clearLocationSetupStatus() {
    localDataSource.clearLocationSetupStatus();
  }
}

/// Custom failure for location-related errors
class LocationFailure extends Failure {
  const LocationFailure({String message = 'Location error occurred'}) : super(message);
}
