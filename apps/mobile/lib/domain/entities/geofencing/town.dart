import 'package:equatable/equatable.dart';

/// Domain entity representing a town/city with delivery services
class Town extends Equatable {
  final String id;
  final String name;
  final String state;
  final String country;
  
  // Delivery settings
  final int deliveryFee;
  final int minOrderAmount;
  final String estimatedDeliveryTime;
  final String currency;
  
  // Status
  final bool isActive;
  final DateTime? launchDate;
  
  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Town({
    required this.id,
    required this.name,
    required this.state,
    this.country = 'India',
    required this.deliveryFee,
    required this.minOrderAmount,
    required this.estimatedDeliveryTime,
    this.currency = 'INR',
    required this.isActive,
    this.launchDate,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        state,
        country,
        deliveryFee,
        minOrderAmount,
        estimatedDeliveryTime,
        currency,
        isActive,
        launchDate,
        createdAt,
        updatedAt,
      ];

  /// Creates a copy of this Town with the given fields replaced
  Town copyWith({
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
    return Town(
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

  @override
  String toString() {
    return 'Town(id: $id, name: $name, state: $state, isActive: $isActive)';
  }
}
