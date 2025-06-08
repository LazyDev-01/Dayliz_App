import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/geofencing/delivery_zone.dart';
import '../../repositories/geofencing_repository.dart';

/// Use case for saving user's location with zone detection
class SaveUserLocationUseCase implements UseCase<void, SaveUserLocationParams> {
  final GeofencingRepository repository;

  SaveUserLocationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveUserLocationParams params) async {
    // First detect the zone for the coordinates
    final zoneDetectionResult = await repository.detectZone(params.coordinates);
    
    return zoneDetectionResult.fold(
      (failure) => Left(failure),
      (detectionResult) async {
        // Save the location with detected zone information
        return await repository.saveUserLocation(
          userId: params.userId,
          coordinates: params.coordinates,
          addressText: params.addressText,
          formattedAddress: params.formattedAddress,
          placeId: params.placeId,
          zoneId: detectionResult.zone?.id,
          townId: detectionResult.town?.id,
          locationType: params.locationType,
          isPrimary: params.isPrimary,
        );
      },
    );
  }
}

/// Parameters for saving user location
class SaveUserLocationParams {
  final String userId;
  final LatLng coordinates;
  final String addressText;
  final String? formattedAddress;
  final String? placeId;
  final String locationType; // 'gps', 'manual', 'search'
  final bool isPrimary;

  const SaveUserLocationParams({
    required this.userId,
    required this.coordinates,
    required this.addressText,
    this.formattedAddress,
    this.placeId,
    required this.locationType,
    this.isPrimary = false,
  });
}

/// Use case for getting user's saved locations
class GetUserLocationsUseCase implements UseCase<List<Map<String, dynamic>>, String> {
  final GeofencingRepository repository;

  GetUserLocationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(String userId) async {
    return await repository.getUserLocations(userId);
  }
}

/// Use case for updating user's primary location
class UpdatePrimaryLocationUseCase implements UseCase<void, UpdatePrimaryLocationParams> {
  final GeofencingRepository repository;

  UpdatePrimaryLocationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePrimaryLocationParams params) async {
    return await repository.updatePrimaryLocation(params.userId, params.locationId);
  }
}

/// Parameters for updating primary location
class UpdatePrimaryLocationParams {
  final String userId;
  final String locationId;

  const UpdatePrimaryLocationParams({
    required this.userId,
    required this.locationId,
  });
}

/// Use case for deleting a user location
class DeleteUserLocationUseCase implements UseCase<void, String> {
  final GeofencingRepository repository;

  DeleteUserLocationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String locationId) async {
    return await repository.deleteUserLocation(locationId);
  }
}
