import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/banner.dart';
import '../../domain/repositories/banner_repository.dart';
import '../datasources/banner_remote_data_source.dart';
import '../datasources/banner_local_data_source.dart';
import '../models/banner_model.dart';

/// Implementation of BannerRepository with caching support
class BannerRepositoryImpl implements BannerRepository {
  final BannerRemoteDataSource remoteDataSource;
  final BannerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  BannerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Banner>>> getActiveBanners() async {
    // Cache-first strategy: Try cache first, then network
    try {
      // 1. Try to get from cache first (fastest)
      if (await localDataSource.hasCachedBanners()) {
        try {
          final cachedBanners = await localDataSource.getCachedBanners();
          if (cachedBanners.isNotEmpty) {
            print('✅ Returning ${cachedBanners.length} banners from cache');
            return Right(cachedBanners);
          }
        } on CacheException catch (e) {
          print('⚠️ Cache read failed: ${e.message}');
          // Continue to network fetch
        }
      }

      // 2. Check network connectivity
      if (await networkInfo.isConnected) {
        try {
          // Fetch from network
          final remoteBanners = await remoteDataSource.getActiveBanners();

          // Cache the fresh data for next time
          try {
            await localDataSource.cacheBanners(remoteBanners);
          } catch (e) {
            print('⚠️ Failed to cache banners: $e');
            // Don't fail the request if caching fails
          }

          print('✅ Returning ${remoteBanners.length} banners from network');
          return Right(remoteBanners);
        } on ServerException catch (e) {
          return Left(ServerFailure(
            message: e.message,
            statusCode: e.code,
          ));
        } on NetworkException catch (e) {
          return Left(NetworkFailure(
            message: e.message,
          ));
        }
      } else {
        // 3. No network - try to return stale cache if available
        try {
          final cachedBanners = await localDataSource.getCachedBanners();
          print('✅ Returning ${cachedBanners.length} stale banners from cache (offline)');
          return Right(cachedBanners);
        } on CacheException catch (e) {
          return Left(NetworkFailure(
            message: 'No internet connection and no cached data available',
          ));
        }
      }
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
