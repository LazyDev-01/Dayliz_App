import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../datasources/coupon_local_data_source.dart';
import '../datasources/coupon_remote_data_source.dart';
import '../models/coupon_model.dart';

/// Implementation of [CouponRepository]
class CouponRepositoryImpl implements CouponRepository {
  final CouponRemoteDataSource remoteDataSource;
  final CouponLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CouponRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Coupon>>> getAvailableCoupons({
    int page = 1,
    int limit = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteCoupons = await remoteDataSource.getAvailableCoupons(
          page: page,
          limit: limit,
        );
        
        // Cache coupons locally (only for first page)
        if (page == 1) {
          await localDataSource.cacheAvailableCoupons(remoteCoupons);
        }
        
        return Right(remoteCoupons);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final localCoupons = await localDataSource.getCachedAvailableCoupons();
        return Right(localCoupons);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<Coupon>>> getUserCoupons({
    int page = 1,
    int limit = 20,
    bool? isUsed,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final remoteCoupons = await remoteDataSource.getUserCoupons(
          userId: userId,
          page: page,
          limit: limit,
          isUsed: isUsed,
        );
        
        // Cache user coupons locally (only for first page)
        if (page == 1 && isUsed == null) {
          await localDataSource.cacheUserCoupons(userId, remoteCoupons);
        }
        
        return Right(remoteCoupons);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final localCoupons = await localDataSource.getCachedUserCoupons(userId);
        
        // Apply filters locally if needed
        var filteredCoupons = localCoupons.where((coupon) {
          if (isUsed != null) {
            return coupon.isUsed == isUsed;
          }
          return true;
        }).toList();

        // Apply pagination
        final startIndex = (page - 1) * limit;
        final endIndex = startIndex + limit;
        
        if (startIndex >= filteredCoupons.length) {
          return const Right([]);
        }

        filteredCoupons = filteredCoupons.sublist(
          startIndex,
          endIndex > filteredCoupons.length ? filteredCoupons.length : endIndex,
        );

        return Right(filteredCoupons);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Coupon>> getCouponByCode(String code) async {
    if (await networkInfo.isConnected) {
      try {
        final coupon = await remoteDataSource.getCouponByCode(code);
        await localDataSource.cacheCoupon(coupon);
        return Right(coupon);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final cachedCoupon = await localDataSource.getCachedCouponByCode(code);
        if (cachedCoupon != null) {
          return Right(cachedCoupon);
        } else {
          return const Left(CacheFailure(message: 'Coupon not found in cache'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Coupon>> getCouponById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final coupon = await remoteDataSource.getCouponById(id);
        await localDataSource.cacheCoupon(coupon);
        return Right(coupon);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, CouponApplicationResult>> validateCoupon({
    required String couponCode,
    required double orderValue,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.validateCoupon(
          couponCode: couponCode,
          orderValue: orderValue,
          userId: userId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserCoupon>> applyCouponToUser({
    required String couponId,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userCoupon = await remoteDataSource.applyCouponToUser(
          couponId: couponId,
          userId: userId,
        );
        
        // Clear user coupons cache to force refresh
        await localDataSource.clearUserCoupons(userId);
        
        return Right(userCoupon);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserCoupon>> useCoupon({
    required String couponCode,
    required String userId,
    required String orderId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userCoupon = await remoteDataSource.useCoupon(
          couponCode: couponCode,
          userId: userId,
          orderId: orderId,
        );
        
        // Clear user coupons cache to force refresh
        await localDataSource.clearUserCoupons(userId);
        
        return Right(userCoupon);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCouponUsageStats(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getCouponUsageStats(userId);
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Coupon>>> searchCoupons({
    required String keyword,
    int page = 1,
    int limit = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final coupons = await remoteDataSource.searchCoupons(
          keyword: keyword,
          page: page,
          limit: limit,
        );
        return Right(coupons);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Coupon>>> getTrendingCoupons({
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final coupons = await remoteDataSource.getTrendingCoupons(limit: limit);
        await localDataSource.cacheTrendingCoupons(coupons);
        return Right(coupons);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final cachedCoupons = await localDataSource.getCachedTrendingCoupons();
        return Right(cachedCoupons);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<Coupon>>> getCouponsByCategory({
    required String category,
    int page = 1,
    int limit = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final coupons = await remoteDataSource.getCouponsByCategory(
          category: category,
          page: page,
          limit: limit,
        );
        return Right(coupons);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasUserCollectedCoupon({
    required String userId,
    required String couponId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final hasCollected = await remoteDataSource.hasUserCollectedCoupon(
          userId: userId,
          couponId: couponId,
        );
        return Right(hasCollected);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<UserCoupon>>> getUserCouponHistory({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final history = await remoteDataSource.getUserCouponHistory(
          userId: userId,
          page: page,
          limit: limit,
        );
        return Right(history);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Coupon?>> getBestCouponForOrder({
    required double orderValue,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final bestCoupon = await remoteDataSource.getBestCouponForOrder(
          orderValue: orderValue,
          userId: userId,
        );
        await localDataSource.cacheBestCouponForOrder(userId, orderValue, bestCoupon);
        return Right(bestCoupon);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final cachedBestCoupon = await localDataSource.getCachedBestCouponForOrder(userId, orderValue);
        return Right(cachedBestCoupon);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<Coupon>>> getExpiringSoonCoupons({
    required String userId,
    int daysThreshold = 7,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final coupons = await remoteDataSource.getExpiringSoonCoupons(
          userId: userId,
          daysThreshold: daysThreshold,
        );
        return Right(coupons);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Get current user ID from authentication service
  Future<String?> _getCurrentUserId() async {
    try {
      // TODO: Implement with actual auth service
      // For now, returning a mock user ID
      return 'mock-user-id';
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }
}
