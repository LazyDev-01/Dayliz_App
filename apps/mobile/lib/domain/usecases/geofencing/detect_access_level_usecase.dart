import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/geofencing/delivery_zone.dart';
import '../../entities/geofencing/enhanced_zone_detection_result.dart';
import '../../repositories/geofencing_repository.dart';
import '../../../core/services/geofencing_service.dart';
import '../../../data/datasources/geofencing_hardcoded_data.dart';

/// Use case for two-tier location validation (city + delivery zone)
class DetectAccessLevelUseCase implements UseCase<EnhancedZoneDetectionResult, DetectAccessLevelParams> {
  final GeofencingRepository repository;

  DetectAccessLevelUseCase(this.repository);

  @override
  Future<Either<Failure, EnhancedZoneDetectionResult>> call(DetectAccessLevelParams params) async {
    try {
      // Tier 1: Check city boundaries first (fast local check)
      final cityBoundary = GeofencingHardcodedData.getTuraCityBoundary();
      
      if (cityBoundary == null) {
        return Right(EnhancedZoneDetectionResult.error(
          coordinates: params.coordinates,
          errorMessage: 'City boundary data not available',
        ));
      }

      final isInCity = GeofencingService.isPointInPolygon(
        params.coordinates, 
        cityBoundary.boundaryCoordinates,
      );

      if (!isInCity) {
        // Outside city - no access
        return Right(EnhancedZoneDetectionResult.noAccess(
          coordinates: params.coordinates,
          customMessage: 'We don\'t serve this area yet, but we\'re expanding soon!',
        ));
      }

      // Tier 2: Check delivery zones (may involve network call)
      final zoneResult = await repository.detectZone(params.coordinates);
      
      return zoneResult.fold(
        (failure) => Right(EnhancedZoneDetectionResult.error(
          coordinates: params.coordinates,
          errorMessage: failure.message,
        )),
        (zoneDetectionResult) {
          if (zoneDetectionResult.isSuccess) {
            // In delivery zone - full access
            return Right(EnhancedZoneDetectionResult.fullAccess(
              coordinates: params.coordinates,
              deliveryZone: zoneDetectionResult.zone!,
              town: zoneDetectionResult.town!,
              cityBoundary: cityBoundary,
            ));
          } else {
            // In city but outside delivery zone - viewing only
            return Right(EnhancedZoneDetectionResult.viewingOnly(
              coordinates: params.coordinates,
              cityBoundary: cityBoundary,
              customMessage: 'You can browse our products, but we don\'t deliver to this area yet.',
            ));
          }
        },
      );
    } catch (e) {
      return Right(EnhancedZoneDetectionResult.error(
        coordinates: params.coordinates,
        errorMessage: 'Failed to validate location: ${e.toString()}',
      ));
    }
  }
}

/// Parameters for access level detection
class DetectAccessLevelParams {
  final LatLng coordinates;

  const DetectAccessLevelParams({required this.coordinates});
}


