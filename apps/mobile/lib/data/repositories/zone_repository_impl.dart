import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/zone.dart';
import '../../domain/repositories/zone_repository.dart';
import '../datasources/zone_remote_data_source.dart';

/// Implementation of ZoneRepository
class ZoneRepositoryImpl implements ZoneRepository {
  final ZoneRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ZoneRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Zone?>> getZoneForLocation(
    double latitude,
    double longitude,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final zoneModel = await remoteDataSource.getZoneForLocation(
          latitude,
          longitude,
        );
        return Right(zoneModel?.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Zone>> getZoneById(String zoneId) async {
    if (await networkInfo.isConnected) {
      try {
        final zoneModel = await remoteDataSource.getZoneById(zoneId);
        return Right(zoneModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Zone>>> getActiveZones() async {
    if (await networkInfo.isConnected) {
      try {
        final zoneModels = await remoteDataSource.getActiveZones();
        final zones = zoneModels.map((model) => model.toEntity()).toList();
        return Right(zones);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLocationInDeliveryZone(
    double latitude,
    double longitude,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final isInZone = await remoteDataSource.isLocationInDeliveryZone(
          latitude,
          longitude,
        );
        return Right(isInZone);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Zone?>> getNearestZone(
    double latitude,
    double longitude,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final zoneModel = await remoteDataSource.getNearestZone(
          latitude,
          longitude,
        );
        return Right(zoneModel?.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
