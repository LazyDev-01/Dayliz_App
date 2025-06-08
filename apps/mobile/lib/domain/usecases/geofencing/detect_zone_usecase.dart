import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/geofencing/delivery_zone.dart';
import '../../entities/geofencing/zone_detection_result.dart';
import '../../repositories/geofencing_repository.dart';

/// Use case for detecting which delivery zone contains given coordinates
class DetectZoneUseCase implements UseCase<ZoneDetectionResult, DetectZoneParams> {
  final GeofencingRepository repository;

  DetectZoneUseCase(this.repository);

  @override
  Future<Either<Failure, ZoneDetectionResult>> call(DetectZoneParams params) async {
    return await repository.detectZone(params.coordinates);
  }
}

/// Parameters for zone detection
class DetectZoneParams {
  final LatLng coordinates;

  const DetectZoneParams({required this.coordinates});
}

/// Use case for checking if delivery is available at given coordinates
class CheckDeliveryAvailabilityUseCase implements UseCase<bool, DetectZoneParams> {
  final GeofencingRepository repository;

  CheckDeliveryAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DetectZoneParams params) async {
    return await repository.isDeliveryAvailable(params.coordinates);
  }
}

/// Use case for finding the closest zone to given coordinates
class FindClosestZoneUseCase implements UseCase<DeliveryZone?, DetectZoneParams> {
  final GeofencingRepository repository;

  FindClosestZoneUseCase(this.repository);

  @override
  Future<Either<Failure, DeliveryZone?>> call(DetectZoneParams params) async {
    return await repository.findClosestZone(params.coordinates);
  }
}
