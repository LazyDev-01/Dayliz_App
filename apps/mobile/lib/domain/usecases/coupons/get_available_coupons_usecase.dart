import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/coupon.dart';
import '../../repositories/coupon_repository.dart';

/// Use case for getting available coupons
class GetAvailableCouponsUseCase implements UseCase<List<Coupon>, GetAvailableCouponsParams> {
  final CouponRepository repository;

  GetAvailableCouponsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Coupon>>> call(GetAvailableCouponsParams params) async {
    return await repository.getAvailableCoupons(
      page: params.page,
      limit: params.limit,
    );
  }
}

/// Parameters for getting available coupons
class GetAvailableCouponsParams extends Equatable {
  final int page;
  final int limit;

  const GetAvailableCouponsParams({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}

/// Use case for getting user's coupons
class GetUserCouponsUseCase implements UseCase<List<Coupon>, GetUserCouponsParams> {
  final CouponRepository repository;

  GetUserCouponsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Coupon>>> call(GetUserCouponsParams params) async {
    return await repository.getUserCoupons(
      page: params.page,
      limit: params.limit,
      isUsed: params.isUsed,
    );
  }
}

/// Parameters for getting user's coupons
class GetUserCouponsParams extends Equatable {
  final int page;
  final int limit;
  final bool? isUsed;

  const GetUserCouponsParams({
    this.page = 1,
    this.limit = 20,
    this.isUsed,
  });

  @override
  List<Object?> get props => [page, limit, isUsed];
}

/// Use case for validating coupon
class ValidateCouponUseCase implements UseCase<CouponApplicationResult, ValidateCouponParams> {
  final CouponRepository repository;

  ValidateCouponUseCase(this.repository);

  @override
  Future<Either<Failure, CouponApplicationResult>> call(ValidateCouponParams params) async {
    return await repository.validateCoupon(
      couponCode: params.couponCode,
      orderValue: params.orderValue,
      userId: params.userId,
    );
  }
}

/// Parameters for validating coupon
class ValidateCouponParams extends Equatable {
  final String couponCode;
  final double orderValue;
  final String userId;

  const ValidateCouponParams({
    required this.couponCode,
    required this.orderValue,
    required this.userId,
  });

  @override
  List<Object?> get props => [couponCode, orderValue, userId];
}

/// Use case for applying coupon to user
class ApplyCouponToUserUseCase implements UseCase<UserCoupon, ApplyCouponToUserParams> {
  final CouponRepository repository;

  ApplyCouponToUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserCoupon>> call(ApplyCouponToUserParams params) async {
    return await repository.applyCouponToUser(
      couponId: params.couponId,
      userId: params.userId,
    );
  }
}

/// Parameters for applying coupon to user
class ApplyCouponToUserParams extends Equatable {
  final String couponId;
  final String userId;

  const ApplyCouponToUserParams({
    required this.couponId,
    required this.userId,
  });

  @override
  List<Object?> get props => [couponId, userId];
}

/// Use case for using coupon
class UseCouponUseCase implements UseCase<UserCoupon, UseCouponParams> {
  final CouponRepository repository;

  UseCouponUseCase(this.repository);

  @override
  Future<Either<Failure, UserCoupon>> call(UseCouponParams params) async {
    return await repository.useCoupon(
      couponCode: params.couponCode,
      userId: params.userId,
      orderId: params.orderId,
    );
  }
}

/// Parameters for using coupon
class UseCouponParams extends Equatable {
  final String couponCode;
  final String userId;
  final String orderId;

  const UseCouponParams({
    required this.couponCode,
    required this.userId,
    required this.orderId,
  });

  @override
  List<Object?> get props => [couponCode, userId, orderId];
}

/// Use case for getting best coupon for order
class GetBestCouponForOrderUseCase implements UseCase<Coupon?, GetBestCouponForOrderParams> {
  final CouponRepository repository;

  GetBestCouponForOrderUseCase(this.repository);

  @override
  Future<Either<Failure, Coupon?>> call(GetBestCouponForOrderParams params) async {
    return await repository.getBestCouponForOrder(
      orderValue: params.orderValue,
      userId: params.userId,
    );
  }
}

/// Parameters for getting best coupon for order
class GetBestCouponForOrderParams extends Equatable {
  final double orderValue;
  final String userId;

  const GetBestCouponForOrderParams({
    required this.orderValue,
    required this.userId,
  });

  @override
  List<Object?> get props => [orderValue, userId];
}

/// Use case for searching coupons
class SearchCouponsUseCase implements UseCase<List<Coupon>, SearchCouponsParams> {
  final CouponRepository repository;

  SearchCouponsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Coupon>>> call(SearchCouponsParams params) async {
    return await repository.searchCoupons(
      keyword: params.keyword,
      page: params.page,
      limit: params.limit,
    );
  }
}

/// Parameters for searching coupons
class SearchCouponsParams extends Equatable {
  final String keyword;
  final int page;
  final int limit;

  const SearchCouponsParams({
    required this.keyword,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [keyword, page, limit];
}

/// Use case for getting trending coupons
class GetTrendingCouponsUseCase implements UseCase<List<Coupon>, GetTrendingCouponsParams> {
  final CouponRepository repository;

  GetTrendingCouponsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Coupon>>> call(GetTrendingCouponsParams params) async {
    return await repository.getTrendingCoupons(
      limit: params.limit,
    );
  }
}

/// Parameters for getting trending coupons
class GetTrendingCouponsParams extends Equatable {
  final int limit;

  const GetTrendingCouponsParams({
    this.limit = 10,
  });

  @override
  List<Object?> get props => [limit];
}
