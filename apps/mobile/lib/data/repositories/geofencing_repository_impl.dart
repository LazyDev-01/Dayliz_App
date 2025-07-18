import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/services/geofencing_service.dart';
import '../../domain/entities/geofencing/delivery_zone.dart';
import '../../domain/entities/geofencing/town.dart';
import '../../domain/entities/geofencing/zone_detection_result.dart';
import '../../domain/repositories/geofencing_repository.dart';
import '../datasources/geofencing_remote_data_source.dart';

/// Implementation of GeofencingRepository
class GeofencingRepositoryImpl implements GeofencingRepository {
  final GeofencingRemoteDataSource remoteDataSource;

  GeofencingRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Town>>> getActiveTowns() async {
    try {
      final townModels = await remoteDataSource.getActiveTowns();
      final towns = townModels.map((model) => model.toDomain()).toList();
      return Right(towns);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch towns: $e'));
    }
  }

  @override
  Future<Either<Failure, Town>> getTownById(String townId) async {
    try {
      final townModel = await remoteDataSource.getTownById(townId);
      return Right(townModel.toDomain());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch town: $e'));
    }
  }

  @override
  Future<Either<Failure, Town?>> getTownByNameAndState(String name, String state) async {
    try {
      final townModel = await remoteDataSource.getTownByNameAndState(name, state);
      return Right(townModel?.toDomain());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch town: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DeliveryZone>>> getZonesForTown(String townId) async {
    try {
      final zoneModels = await remoteDataSource.getZonesForTown(townId);
      final zones = zoneModels.map((model) => model.toDomain()).toList();
      return Right(zones);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch zones: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DeliveryZone>>> getAllActiveZones() async {
    try {
      final zoneModels = await remoteDataSource.getAllActiveZones();
      final zones = zoneModels.map((model) => model.toDomain()).toList();
      return Right(zones);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch zones: $e'));
    }
  }

  @override
  Future<Either<Failure, DeliveryZone>> getZoneById(String zoneId) async {
    try {
      final zoneModel = await remoteDataSource.getZoneById(zoneId);
      return Right(zoneModel.toDomain());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch zone: $e'));
    }
  }

  @override
  Future<Either<Failure, ZoneDetectionResult>> detectZone(LatLng coordinates) async {
    try {
      // Get all active zones
      final zonesResult = await getAllActiveZones();

      return zonesResult.fold(
        (failure) => Left(failure),
        (zones) {
          // Check each zone to see if coordinates fall within it
          for (final zone in zones) {
            if (GeofencingService.isPointInZone(coordinates, zone)) {
              // Found a zone! Create a town from zone data (simplified structure)
              final town = Town(
                id: zone.id, // Use zone ID as town ID
                name: zone.name, // Use zone name as town name
                state: 'Meghalaya', // Default state (can be made dynamic later)
                deliveryFee: 25, // Default delivery fee
                minOrderAmount: 200, // Default minimum order
                estimatedDeliveryTime: '30-45 mins', // Default delivery time
                isActive: zone.isActive,
              );

              return Right(ZoneDetectionResult.found(
                zone: zone,
                town: town,
                coordinates: coordinates,
              ));
            }
          }

          // No zone found
          return Right(ZoneDetectionResult.notFound(
            coordinates: coordinates,
            message: 'We don\'t deliver to this area yet, but we\'re expanding soon!',
          ));
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to detect zone: $e'));
    }
  }

  @override
  Future<Either<Failure, DeliveryZone?>> findClosestZone(LatLng coordinates) async {
    try {
      final zonesResult = await getAllActiveZones();
      
      return zonesResult.fold(
        (failure) => Left(failure),
        (zones) {
          final closestZone = GeofencingService.findClosestZone(coordinates, zones);
          return Right(closestZone);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to find closest zone: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isDeliveryAvailable(LatLng coordinates) async {
    try {
      final detectionResult = await detectZone(coordinates);
      
      return detectionResult.fold(
        (failure) => Left(failure),
        (result) => Right(result.isInZone),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to check delivery availability: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveUserLocation({
    required String userId,
    required LatLng coordinates,
    required String addressText,
    String? formattedAddress,
    String? placeId,
    String? zoneId,
    String? townId,
    required String locationType,
    bool isPrimary = false,
  }) async {
    try {
      await remoteDataSource.saveUserLocation(
        userId: userId,
        coordinates: coordinates,
        addressText: addressText,
        formattedAddress: formattedAddress,
        placeId: placeId,
        zoneId: zoneId,
        townId: townId,
        locationType: locationType,
        isPrimary: isPrimary,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to save user location: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserLocations(String userId) async {
    try {
      final locations = await remoteDataSource.getUserLocations(userId);
      return Right(locations);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to fetch user locations: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePrimaryLocation(String userId, String locationId) async {
    try {
      await remoteDataSource.updatePrimaryLocation(userId, locationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update primary location: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUserLocation(String locationId) async {
    try {
      await remoteDataSource.deleteUserLocation(locationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete user location: $e'));
    }
  }
}

/// Custom failure for geofencing-related errors
class GeofencingFailure extends Failure {
  const GeofencingFailure({String message = 'Geofencing error occurred'}) : super(message);
}
