import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/zone.dart';
import '../../repositories/location_repository.dart';

/// Parameters for zone validation
class ValidateDeliveryZoneParams extends Equatable {
  final LocationCoordinates coordinates;

  const ValidateDeliveryZoneParams({
    required this.coordinates,
  });

  @override
  List<Object> get props => [coordinates];
}

/// Use case for validating if location is within delivery zone
class ValidateDeliveryZoneUseCase implements UseCase<ZoneValidationResult, ValidateDeliveryZoneParams> {
  final LocationRepository repository;

  ValidateDeliveryZoneUseCase(this.repository);

  @override
  Future<Either<Failure, ZoneValidationResult>> call(ValidateDeliveryZoneParams params) async {
    return await repository.validateDeliveryZone(params.coordinates);
  }
}

/// Combined use case for getting location and validating zone in one step
class GetLocationAndValidateZoneUseCase implements UseCase<ZoneValidationResult, NoParams> {
  final LocationRepository repository;

  GetLocationAndValidateZoneUseCase(this.repository);

  @override
  Future<Either<Failure, ZoneValidationResult>> call(NoParams params) async {
    // First get current location
    final locationResult = await repository.getCurrentLocation();
    
    return locationResult.fold(
      (failure) => Left(failure),
      (coordinates) async {
        // Then validate the zone
        return await repository.validateDeliveryZone(coordinates);
      },
    );
  }
}
