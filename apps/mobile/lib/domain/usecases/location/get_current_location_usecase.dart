import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/zone.dart';
import '../../repositories/location_repository.dart';

/// Use case for getting current GPS location
class GetCurrentLocationUseCase implements UseCase<LocationCoordinates, NoParams> {
  final LocationRepository repository;

  GetCurrentLocationUseCase(this.repository);

  @override
  Future<Either<Failure, LocationCoordinates>> call(NoParams params) async {
    return await repository.getCurrentLocation();
  }
}
