/// Coupon model for discount management
class Coupon {
  final String code;
  final String title;
  final String description;
  final CouponType type;
  final double value;
  final double minimumOrderValue;
  final double? maximumDiscount;
  final DateTime? expiryDate;
  final bool isActive;
  final List<String>? applicableCategories;

  const Coupon({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.minimumOrderValue,
    this.maximumDiscount,
    this.expiryDate,
    this.isActive = true,
    this.applicableCategories,
  });

  /// Calculate discount amount for given cart total
  double calculateDiscount(double cartTotal) {
    if (!isActive || cartTotal < minimumOrderValue) {
      return 0.0;
    }

    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) {
      return 0.0;
    }

    double discount = 0.0;

    switch (type) {
      case CouponType.percentage:
        discount = cartTotal * (value / 100);
        break;
      case CouponType.fixed:
        discount = value;
        break;
      case CouponType.freeDelivery:
        // For free delivery, return delivery fee amount
        // This will be handled separately in the cart calculation
        discount = 0.0;
        break;
    }

    // Apply maximum discount limit if specified
    if (maximumDiscount != null && discount > maximumDiscount!) {
      discount = maximumDiscount!;
    }

    return discount;
  }

  /// Check if coupon is valid for current conditions
  bool isValid(double cartTotal) {
    if (!isActive) return false;
    if (cartTotal < minimumOrderValue) return false;
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) return false;
    return true;
  }

  /// Get user-friendly discount description
  String getDiscountDescription() {
    switch (type) {
      case CouponType.percentage:
        String desc = '${value.toInt()}% off';
        if (maximumDiscount != null) {
          desc += ' (max ₹${maximumDiscount!.toInt()})';
        }
        return desc;
      case CouponType.fixed:
        return '₹${value.toInt()} off';
      case CouponType.freeDelivery:
        return 'Free delivery';
    }
  }

  /// Get minimum order requirement text
  String getMinimumOrderText() {
    if (minimumOrderValue > 0) {
      return 'Min order ₹${minimumOrderValue.toInt()}';
    }
    return 'No minimum order';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coupon && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Coupon(code: $code, type: $type, value: $value)';
}

/// Types of coupons available
enum CouponType {
  percentage,
  fixed,
  freeDelivery,
}

/// Applied coupon state
class AppliedCoupon {
  final Coupon coupon;
  final double discountAmount;
  final bool givesFreeDelivery;

  const AppliedCoupon({
    required this.coupon,
    required this.discountAmount,
    this.givesFreeDelivery = false,
  });

  @override
  String toString() => 'AppliedCoupon(code: ${coupon.code}, discount: ₹$discountAmount)';
}
