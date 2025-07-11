import '../models/coupon.dart';

/// Service for managing coupons and discount calculations
class CouponService {
  // Mock coupon database - In production, this would come from API
  static final List<Coupon> _availableCoupons = [
    Coupon(
      code: 'WELCOME20',
      title: 'Welcome Offer',
      description: 'Get 20% off on your first order',
      type: CouponType.percentage,
      value: 20,
      minimumOrderValue: 199,
      maximumDiscount: 100,
    ),
    Coupon(
      code: 'SAVE50',
      title: 'Flat ₹50 Off',
      description: 'Flat ₹50 discount on orders above ₹299',
      type: CouponType.fixed,
      value: 50,
      minimumOrderValue: 299,
    ),
    Coupon(
      code: 'FREEDEL',
      title: 'Free Delivery',
      description: 'Get free delivery on any order',
      type: CouponType.freeDelivery,
      value: 0,
      minimumOrderValue: 0,
    ),
    Coupon(
      code: 'BIG100',
      title: 'Big Save',
      description: 'Get ₹100 off on orders above ₹599',
      type: CouponType.fixed,
      value: 100,
      minimumOrderValue: 599,
    ),
    Coupon(
      code: 'PERCENT15',
      title: '15% Off',
      description: 'Get 15% off on orders above ₹399',
      type: CouponType.percentage,
      value: 15,
      minimumOrderValue: 399,
      maximumDiscount: 150,
    ),
  ];

  /// Validate and apply coupon
  static CouponValidationResult validateCoupon(String code, double cartTotal) {
    if (code.trim().isEmpty) {
      return CouponValidationResult.error('Please enter a coupon code');
    }

    final coupon = _availableCoupons.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => throw CouponNotFoundException(),
    );

    try {
      if (!coupon.isValid(cartTotal)) {
        if (cartTotal < coupon.minimumOrderValue) {
          return CouponValidationResult.error(
            'Minimum order value ₹${coupon.minimumOrderValue.toInt()} required',
          );
        }
        if (coupon.expiryDate != null && DateTime.now().isAfter(coupon.expiryDate!)) {
          return CouponValidationResult.error('This coupon has expired');
        }
        return CouponValidationResult.error('This coupon is not valid');
      }

      final discountAmount = coupon.calculateDiscount(cartTotal);
      final givesFreeDelivery = coupon.type == CouponType.freeDelivery;

      final appliedCoupon = AppliedCoupon(
        coupon: coupon,
        discountAmount: discountAmount,
        givesFreeDelivery: givesFreeDelivery,
      );

      return CouponValidationResult.success(appliedCoupon);
    } catch (e) {
      if (e is CouponNotFoundException) {
        return CouponValidationResult.error('Invalid coupon code');
      }
      return CouponValidationResult.error('Failed to apply coupon');
    }
  }

  /// Get all available coupons
  static List<Coupon> getAvailableCoupons() {
    return _availableCoupons.where((coupon) => coupon.isActive).toList();
  }

  /// Get coupons applicable for given cart total
  static List<Coupon> getApplicableCoupons(double cartTotal) {
    return _availableCoupons
        .where((coupon) => coupon.isValid(cartTotal))
        .toList();
  }

  /// Calculate total savings with applied coupon
  static double calculateTotalSavings({
    required double cartTotal,
    required double deliveryFee,
    AppliedCoupon? appliedCoupon,
  }) {
    if (appliedCoupon == null) return 0.0;

    double savings = appliedCoupon.discountAmount;
    
    // Add delivery fee savings if coupon gives free delivery
    if (appliedCoupon.givesFreeDelivery) {
      savings += deliveryFee;
    }

    return savings;
  }
}

/// Result of coupon validation
class CouponValidationResult {
  final bool isSuccess;
  final AppliedCoupon? appliedCoupon;
  final String? errorMessage;

  const CouponValidationResult._({
    required this.isSuccess,
    this.appliedCoupon,
    this.errorMessage,
  });

  factory CouponValidationResult.success(AppliedCoupon appliedCoupon) {
    return CouponValidationResult._(
      isSuccess: true,
      appliedCoupon: appliedCoupon,
    );
  }

  factory CouponValidationResult.error(String message) {
    return CouponValidationResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// Exception for coupon not found
class CouponNotFoundException implements Exception {
  final String message;
  const CouponNotFoundException([this.message = 'Coupon not found']);
}
