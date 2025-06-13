import 'package:equatable/equatable.dart';

/// Domain entity representing a coupon/voucher
class Coupon extends Equatable {
  final String id;
  final String code;
  final String? description;
  final double discountValue;
  final String discountType;
  final double? minimumOrderValue;
  final double? maximumDiscount;
  final DateTime startDate;
  final DateTime endDate;
  final int? usageLimit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Coupon({
    required this.id,
    required this.code,
    this.description,
    required this.discountValue,
    required this.discountType,
    this.minimumOrderValue,
    this.maximumDiscount,
    required this.startDate,
    required this.endDate,
    this.usageLimit,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Discount types
  static const String discountTypePercentage = 'percentage';
  static const String discountTypeFixed = 'fixed';

  /// Check if coupon is currently valid (not expired and active)
  bool get isValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }

  /// Check if coupon is expired
  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  /// Check if coupon is not yet started
  bool get isNotStarted {
    return DateTime.now().isBefore(startDate);
  }

  /// Get days until expiry (negative if expired)
  int get daysUntilExpiry {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  /// Get hours until expiry (negative if expired)
  int get hoursUntilExpiry {
    final now = DateTime.now();
    return endDate.difference(now).inHours;
  }

  /// Check if coupon is expiring soon (within 24 hours)
  bool get isExpiringSoon {
    return hoursUntilExpiry <= 24 && hoursUntilExpiry > 0;
  }

  /// Calculate discount amount for a given order value
  double calculateDiscount(double orderValue) {
    // Check minimum order value requirement
    if (minimumOrderValue != null && orderValue < minimumOrderValue!) {
      return 0.0;
    }

    double discount = 0.0;

    if (discountType == discountTypePercentage) {
      discount = (orderValue * discountValue) / 100;
    } else if (discountType == discountTypeFixed) {
      discount = discountValue;
    }

    // Apply maximum discount limit if specified
    if (maximumDiscount != null && discount > maximumDiscount!) {
      discount = maximumDiscount!;
    }

    // Ensure discount doesn't exceed order value
    if (discount > orderValue) {
      discount = orderValue;
    }

    return discount;
  }

  /// Get formatted discount display text
  String get discountDisplayText {
    if (discountType == discountTypePercentage) {
      return '${discountValue.toInt()}% OFF';
    } else {
      return '₹${discountValue.toInt()} OFF';
    }
  }

  /// Get formatted minimum order text
  String? get minimumOrderText {
    if (minimumOrderValue != null) {
      return 'Min order ₹${minimumOrderValue!.toInt()}';
    }
    return null;
  }

  /// Get formatted maximum discount text
  String? get maximumDiscountText {
    if (maximumDiscount != null && discountType == discountTypePercentage) {
      return 'Max ₹${maximumDiscount!.toInt()}';
    }
    return null;
  }

  /// Get coupon validity status text
  String get validityStatusText {
    if (isExpired) {
      return 'Expired';
    } else if (isNotStarted) {
      return 'Not started';
    } else if (isExpiringSoon) {
      return 'Expires in ${hoursUntilExpiry}h';
    } else if (daysUntilExpiry <= 7) {
      return 'Expires in ${daysUntilExpiry}d';
    } else {
      return 'Valid until ${_formatDate(endDate)}';
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Create a copy with updated fields
  Coupon copyWith({
    String? id,
    String? code,
    String? description,
    double? discountValue,
    String? discountType,
    double? minimumOrderValue,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    int? usageLimit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
      minimumOrderValue: minimumOrderValue ?? this.minimumOrderValue,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      usageLimit: usageLimit ?? this.usageLimit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        description,
        discountValue,
        discountType,
        minimumOrderValue,
        maximumDiscount,
        startDate,
        endDate,
        usageLimit,
        isActive,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Coupon(id: $id, code: $code, discountType: $discountType, discountValue: $discountValue)';
  }
}

/// Domain entity representing a user's coupon usage
class UserCoupon extends Equatable {
  final String id;
  final String userId;
  final String couponId;
  final bool isUsed;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserCoupon({
    required this.id,
    required this.userId,
    required this.couponId,
    this.isUsed = false,
    this.usedAt,
    required this.createdAt,
    this.updatedAt,
  });

  /// Mark coupon as used
  UserCoupon markAsUsed() {
    return copyWith(
      isUsed: true,
      usedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  UserCoupon copyWith({
    String? id,
    String? userId,
    String? couponId,
    bool? isUsed,
    DateTime? usedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserCoupon(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      couponId: couponId ?? this.couponId,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        couponId,
        isUsed,
        usedAt,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserCoupon(id: $id, userId: $userId, couponId: $couponId, isUsed: $isUsed)';
  }
}

/// Coupon application result
class CouponApplicationResult extends Equatable {
  final bool isSuccess;
  final String? errorMessage;
  final double discountAmount;
  final Coupon? coupon;

  const CouponApplicationResult({
    required this.isSuccess,
    this.errorMessage,
    this.discountAmount = 0.0,
    this.coupon,
  });

  /// Create successful result
  factory CouponApplicationResult.success({
    required double discountAmount,
    required Coupon coupon,
  }) {
    return CouponApplicationResult(
      isSuccess: true,
      discountAmount: discountAmount,
      coupon: coupon,
    );
  }

  /// Create failure result
  factory CouponApplicationResult.failure(String errorMessage) {
    return CouponApplicationResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSuccess, errorMessage, discountAmount, coupon];
}
