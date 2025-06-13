import '../../domain/entities/coupon.dart';

/// Model class for [Coupon] with additional functionality for the data layer
class CouponModel extends Coupon {
  const CouponModel({
    required super.id,
    required super.code,
    super.description,
    required super.discountValue,
    required super.discountType,
    super.minimumOrderValue,
    super.maximumDiscount,
    required super.startDate,
    required super.endDate,
    super.usageLimit,
    super.isActive = true,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create CouponModel from JSON
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountValue: (json['discount_value'] as num).toDouble(),
      discountType: json['discount_type'] as String,
      minimumOrderValue: json['minimum_order_value'] != null 
          ? (json['minimum_order_value'] as num).toDouble() 
          : null,
      maximumDiscount: json['maximum_discount'] != null 
          ? (json['maximum_discount'] as num).toDouble() 
          : null,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      usageLimit: json['usage_limit'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  /// Convert CouponModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discount_value': discountValue,
      'discount_type': discountType,
      'minimum_order_value': minimumOrderValue,
      'maximum_discount': maximumDiscount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'usage_limit': usageLimit,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create CouponModel from domain entity
  factory CouponModel.fromEntity(Coupon entity) {
    return CouponModel(
      id: entity.id,
      code: entity.code,
      description: entity.description,
      discountValue: entity.discountValue,
      discountType: entity.discountType,
      minimumOrderValue: entity.minimumOrderValue,
      maximumDiscount: entity.maximumDiscount,
      startDate: entity.startDate,
      endDate: entity.endDate,
      usageLimit: entity.usageLimit,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create a copy with updated fields
  CouponModel copyWithModel({
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
    return CouponModel(
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
}

/// Model class for [UserCoupon] with additional functionality for the data layer
class UserCouponModel extends UserCoupon {
  const UserCouponModel({
    required super.id,
    required super.userId,
    required super.couponId,
    super.isUsed = false,
    super.usedAt,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create UserCouponModel from JSON
  factory UserCouponModel.fromJson(Map<String, dynamic> json) {
    return UserCouponModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      couponId: json['coupon_id'] as String,
      isUsed: json['is_used'] as bool? ?? false,
      usedAt: json['used_at'] != null 
          ? DateTime.parse(json['used_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  /// Convert UserCouponModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'coupon_id': couponId,
      'is_used': isUsed,
      'used_at': usedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create UserCouponModel from domain entity
  factory UserCouponModel.fromEntity(UserCoupon entity) {
    return UserCouponModel(
      id: entity.id,
      userId: entity.userId,
      couponId: entity.couponId,
      isUsed: entity.isUsed,
      usedAt: entity.usedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create a copy with updated fields
  UserCouponModel copyWithModel({
    String? id,
    String? userId,
    String? couponId,
    bool? isUsed,
    DateTime? usedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserCouponModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      couponId: couponId ?? this.couponId,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Extended coupon model with user-specific information
class CouponWithUserInfo extends CouponModel {
  final bool isCollected;
  final bool isUsed;
  final DateTime? collectedAt;
  final DateTime? usedAt;

  const CouponWithUserInfo({
    required super.id,
    required super.code,
    super.description,
    required super.discountValue,
    required super.discountType,
    super.minimumOrderValue,
    super.maximumDiscount,
    required super.startDate,
    required super.endDate,
    super.usageLimit,
    super.isActive = true,
    required super.createdAt,
    super.updatedAt,
    this.isCollected = false,
    this.isUsed = false,
    this.collectedAt,
    this.usedAt,
  });

  /// Create CouponWithUserInfo from JSON with user data
  factory CouponWithUserInfo.fromJsonWithUserData(
    Map<String, dynamic> couponJson,
    Map<String, dynamic>? userCouponJson,
  ) {
    final coupon = CouponModel.fromJson(couponJson);
    
    return CouponWithUserInfo(
      id: coupon.id,
      code: coupon.code,
      description: coupon.description,
      discountValue: coupon.discountValue,
      discountType: coupon.discountType,
      minimumOrderValue: coupon.minimumOrderValue,
      maximumDiscount: coupon.maximumDiscount,
      startDate: coupon.startDate,
      endDate: coupon.endDate,
      usageLimit: coupon.usageLimit,
      isActive: coupon.isActive,
      createdAt: coupon.createdAt,
      updatedAt: coupon.updatedAt,
      isCollected: userCouponJson != null,
      isUsed: userCouponJson?['is_used'] as bool? ?? false,
      collectedAt: userCouponJson?['created_at'] != null 
          ? DateTime.parse(userCouponJson!['created_at'] as String) 
          : null,
      usedAt: userCouponJson?['used_at'] != null 
          ? DateTime.parse(userCouponJson!['used_at'] as String) 
          : null,
    );
  }

  /// Check if coupon can be used by user
  bool get canBeUsed {
    return isCollected && !isUsed && isValid;
  }

  /// Check if coupon can be collected by user
  bool get canBeCollected {
    return !isCollected && isValid;
  }

  /// Get user-specific status text
  String get userStatusText {
    if (isUsed) {
      return 'Used';
    } else if (isCollected) {
      return 'Collected';
    } else if (isExpired) {
      return 'Expired';
    } else if (isNotStarted) {
      return 'Coming soon';
    } else {
      return 'Available';
    }
  }
}
