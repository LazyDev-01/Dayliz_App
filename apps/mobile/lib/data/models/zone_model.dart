import '../../domain/entities/zone.dart';

/// Data model for Zone entity
class ZoneModel extends Zone {
  const ZoneModel({
    required super.id,
    required super.name,
    super.description,
    super.deliveryFee,
    super.minimumOrderAmount,
    required super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  /// Create ZoneModel from JSON
  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      deliveryFee: json['delivery_fee'] != null 
          ? double.parse(json['delivery_fee'].toString())
          : null,
      minimumOrderAmount: json['minimum_order_amount'] != null
          ? double.parse(json['minimum_order_amount'].toString())
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert ZoneModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'delivery_fee': deliveryFee,
      'minimum_order_amount': minimumOrderAmount,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create ZoneModel from domain entity
  factory ZoneModel.fromEntity(Zone zone) {
    return ZoneModel(
      id: zone.id,
      name: zone.name,
      description: zone.description,
      deliveryFee: zone.deliveryFee,
      minimumOrderAmount: zone.minimumOrderAmount,
      isActive: zone.isActive,
      createdAt: zone.createdAt,
      updatedAt: zone.updatedAt,
    );
  }

  /// Convert to domain entity
  Zone toEntity() {
    return Zone(
      id: id,
      name: name,
      description: description,
      deliveryFee: deliveryFee,
      minimumOrderAmount: minimumOrderAmount,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Data model for LocationCoordinates entity
class LocationCoordinatesModel extends LocationCoordinates {
  const LocationCoordinatesModel({
    required super.latitude,
    required super.longitude,
    super.accuracy,
    super.timestamp,
  });

  /// Create LocationCoordinatesModel from JSON
  factory LocationCoordinatesModel.fromJson(Map<String, dynamic> json) {
    return LocationCoordinatesModel(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      accuracy: json['accuracy'] != null
          ? double.parse(json['accuracy'].toString())
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  /// Convert LocationCoordinatesModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  /// Create LocationCoordinatesModel from domain entity
  factory LocationCoordinatesModel.fromEntity(LocationCoordinates coordinates) {
    return LocationCoordinatesModel(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      accuracy: coordinates.accuracy,
      timestamp: coordinates.timestamp,
    );
  }

  /// Convert to domain entity
  LocationCoordinates toEntity() {
    return LocationCoordinates(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp,
    );
  }
}
