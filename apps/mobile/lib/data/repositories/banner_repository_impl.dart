import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/banner.dart';
import '../../domain/repositories/banner_repository.dart';
import '../datasources/banner_remote_data_source.dart';
import '../models/banner_model.dart';

/// Implementation of BannerRepository
class BannerRepositoryImpl implements BannerRepository {
  final BannerRemoteDataSource remoteDataSource;

  BannerRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Banner>>> getActiveBanners() async {
    try {
      final bannerModels = await remoteDataSource.getActiveBanners();
      return Right(bannerModels);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, List<Banner>>> getAllBanners() async {
    try {
      final bannerModels = await remoteDataSource.getAllBanners();
      return Right(bannerModels);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Banner>> getBannerById(String id) async {
    try {
      final bannerModel = await remoteDataSource.getBannerById(id);
      return Right(bannerModel);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(
        message: e.message,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Banner>> createBanner(Banner banner) async {
    try {
      final bannerModel = BannerModel.fromEntity(banner);
      final createdBanner = await remoteDataSource.createBanner(bannerModel);
      return Right(createdBanner);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Banner>> updateBanner(Banner banner) async {
    try {
      final bannerModel = BannerModel.fromEntity(banner);
      final updatedBanner = await remoteDataSource.updateBanner(bannerModel);
      return Right(updatedBanner);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(
        message: e.message,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBanner(String id) async {
    try {
      await remoteDataSource.deleteBanner(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.code,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Unexpected error occurred: $e',
      ));
    }
  }
}
