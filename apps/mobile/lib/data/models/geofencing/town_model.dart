import '../../../domain/entities/geofencing/town.dart';

/// Data model for Town entity with JSON serialization
class TownModel extends Town {
  const TownModel({
    required super.id,
    required super.name,
    required super.state,
    super.country,
    required super.deliveryFee,
    required super.minOrderAmount,
    required super.estimatedDeliveryTime,
    super.currency,
    required super.isActive,
    super.launchDate,
    super.createdAt,
    super.updatedAt,
  });

  /// Create TownModel from JSON
  factory TownModel.fromJson(Map<String, dynamic> json) {
    return TownModel(
      id: json['id'] as String,
      name: json['name'] as String,
      state: json['state'] as String,
      country: json['country'] as String? ?? 'India',
      deliveryFee: json['delivery_fee'] as int,
      minOrderAmount: json['min_order_amount'] as int,
      estimatedDeliveryTime: json['estimated_delivery_time'] as String,
      currency: json['currency'] as String? ?? 'INR',
      isActive: json['is_active'] as bool,
      launchDate: json['launch_date'] != null 
          ? DateTime.parse(json['launch_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert TownModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'country': country,
      'delivery_fee': deliveryFee,
      'min_order_amount': minOrderAmount,
      'estimated_delivery_time': estimatedDeliveryTime,
      'currency': currency,
      'is_active': isActive,
      'launch_date': launchDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Town toDomain() {
    return Town(
      id: id,
      name: name,
      state: state,
      country: country,
      deliveryFee: deliveryFee,
      minOrderAmount: minOrderAmount,
      estimatedDeliveryTime: estimatedDeliveryTime,
      currency: currency,
      isActive: isActive,
      launchDate: launchDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory TownModel.fromDomain(Town town) {
    return TownModel(
      id: town.id,
      name: town.name,
      state: town.state,
      country: town.country,
      deliveryFee: town.deliveryFee,
      minOrderAmount: town.minOrderAmount,
      estimatedDeliveryTime: town.estimatedDeliveryTime,
      currency: town.currency,
      isActive: town.isActive,
      launchDate: town.launchDate,
      createdAt: town.createdAt,
      updatedAt: town.updatedAt,
    );
  }

  /// Create a copy with updated fields
  TownModel copyWith({
    String? id,
    String? name,
    String? state,
    String? country,
    int? deliveryFee,
    int? minOrderAmount,
    String? estimatedDeliveryTime,
    String? currency,
    bool? isActive,
    DateTime? launchDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TownModel(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      country: country ?? this.country,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      launchDate: launchDate ?? this.launchDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
