import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/coupon.dart';

/// Repository interface for coupon-related operations
abstract class CouponRepository {
  /// Get all available coupons for the user
  Future<Either<Failure, List<Coupon>>> getAvailableCoupons({
    int page = 1,
    int limit = 20,
  });

  /// Get user's coupons (assigned/collected coupons)
  Future<Either<Failure, List<Coupon>>> getUserCoupons({
    int page = 1,
    int limit = 20,
    bool? isUsed,
  });

  /// Get coupon by code
  Future<Either<Failure, Coupon>> getCouponByCode(String code);

  /// Get coupon by ID
  Future<Either<Failure, Coupon>> getCouponById(String id);

  /// Validate coupon for a specific order value
  Future<Either<Failure, CouponApplicationResult>> validateCoupon({
    required String couponCode,
    required double orderValue,
    required String userId,
  });

  /// Apply coupon to user's account (collect/claim coupon)
  Future<Either<Failure, UserCoupon>> applyCouponToUser({
    required String couponId,
    required String userId,
  });

  /// Use coupon for an order
  Future<Either<Failure, UserCoupon>> useCoupon({
    required String couponCode,
    required String userId,
    required String orderId,
  });

  /// Get coupon usage statistics for user
  Future<Either<Failure, Map<String, dynamic>>> getCouponUsageStats(String userId);

  /// Search coupons by keyword
  Future<Either<Failure, List<Coupon>>> searchCoupons({
    required String keyword,
    int page = 1,
    int limit = 20,
  });

  /// Get trending/popular coupons
  Future<Either<Failure, List<Coupon>>> getTrendingCoupons({
    int limit = 10,
  });

  /// Get coupons by category/type
  Future<Either<Failure, List<Coupon>>> getCouponsByCategory({
    required String category,
    int page = 1,
    int limit = 20,
  });

  /// Check if user has already collected a specific coupon
  Future<Either<Failure, bool>> hasUserCollectedCoupon({
    required String userId,
    required String couponId,
  });

  /// Get user's coupon usage history
  Future<Either<Failure, List<UserCoupon>>> getUserCouponHistory({
    required String userId,
    int page = 1,
    int limit = 20,
  });

  /// Get best coupon for a specific order value
  Future<Either<Failure, Coupon?>> getBestCouponForOrder({
    required double orderValue,
    required String userId,
  });

  /// Get coupons expiring soon
  Future<Either<Failure, List<Coupon>>> getExpiringSoonCoupons({
    required String userId,
    int daysThreshold = 7,
  });
}
