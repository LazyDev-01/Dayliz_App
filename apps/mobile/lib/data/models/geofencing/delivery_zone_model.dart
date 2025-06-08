import '../../../domain/entities/geofencing/delivery_zone.dart';

/// Data model for DeliveryZone entity with JSON serialization
class DeliveryZoneModel extends DeliveryZone {
  const DeliveryZoneModel({
    required super.id,
    required super.name,
    required super.townId,
    required super.zoneNumber,
    required super.zoneType,
    super.boundaryCoordinates,
    super.center,
    super.radiusKm,
    super.customDeliveryFee,
    super.customMinOrder,
    super.customDeliveryTime,
    required super.isActive,
    super.priority,
    super.description,
    super.createdAt,
    super.updatedAt,
  });

  /// Create DeliveryZoneModel from JSON
  factory DeliveryZoneModel.fromJson(Map<String, dynamic> json) {
    final zoneType = ZoneType.fromString(json['zone_type'] as String);
    
    List<LatLng>? boundaryCoordinates;
    if (json['boundary_coordinates'] != null) {
      final coordsJson = json['boundary_coordinates'] as List<dynamic>;
      boundaryCoordinates = coordsJson
          .map((coord) => LatLng.fromJson(coord as Map<String, dynamic>))
          .toList();
    }

    LatLng? center;
    if (json['center_lat'] != null && json['center_lng'] != null) {
      center = LatLng(
        (json['center_lat'] as num).toDouble(),
        (json['center_lng'] as num).toDouble(),
      );
    }

    return DeliveryZoneModel(
      id: json['id'] as String,
      name: json['name'] as String,
      townId: json['town_id'] as String,
      zoneNumber: json['zone_number'] as int,
      zoneType: zoneType,
      boundaryCoordinates: boundaryCoordinates,
      center: center,
      radiusKm: json['radius_km'] != null 
          ? (json['radius_km'] as num).toDouble()
          : null,
      customDeliveryFee: json['custom_delivery_fee'] as int?,
      customMinOrder: json['custom_min_order'] as int?,
      customDeliveryTime: json['custom_delivery_time'] as String?,
      isActive: json['is_active'] as bool,
      priority: json['priority'] as int? ?? 1,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert DeliveryZoneModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'town_id': townId,
      'zone_number': zoneNumber,
      'zone_type': zoneType.value,
      'boundary_coordinates': boundaryCoordinates?.map((coord) => coord.toJson()).toList(),
      'center_lat': center?.latitude,
      'center_lng': center?.longitude,
      'radius_km': radiusKm,
      'custom_delivery_fee': customDeliveryFee,
      'custom_min_order': customMinOrder,
      'custom_delivery_time': customDeliveryTime,
      'is_active': isActive,
      'priority': priority,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  DeliveryZone toDomain() {
    return DeliveryZone(
      id: id,
      name: name,
      townId: townId,
      zoneNumber: zoneNumber,
      zoneType: zoneType,
      boundaryCoordinates: boundaryCoordinates,
      center: center,
      radiusKm: radiusKm,
      customDeliveryFee: customDeliveryFee,
      customMinOrder: customMinOrder,
      customDeliveryTime: customDeliveryTime,
      isActive: isActive,
      priority: priority,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory DeliveryZoneModel.fromDomain(DeliveryZone zone) {
    return DeliveryZoneModel(
      id: zone.id,
      name: zone.name,
      townId: zone.townId,
      zoneNumber: zone.zoneNumber,
      zoneType: zone.zoneType,
      boundaryCoordinates: zone.boundaryCoordinates,
      center: zone.center,
      radiusKm: zone.radiusKm,
      customDeliveryFee: zone.customDeliveryFee,
      customMinOrder: zone.customMinOrder,
      customDeliveryTime: zone.customDeliveryTime,
      isActive: zone.isActive,
      priority: zone.priority,
      description: zone.description,
      createdAt: zone.createdAt,
      updatedAt: zone.updatedAt,
    );
  }

  /// Create a copy with updated fields
  DeliveryZoneModel copyWith({
    String? id,
    String? name,
    String? townId,
    int? zoneNumber,
    ZoneType? zoneType,
    List<LatLng>? boundaryCoordinates,
    LatLng? center,
    double? radiusKm,
    int? customDeliveryFee,
    int? customMinOrder,
    String? customDeliveryTime,
    bool? isActive,
    int? priority,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      townId: townId ?? this.townId,
      zoneNumber: zoneNumber ?? this.zoneNumber,
      zoneType: zoneType ?? this.zoneType,
      boundaryCoordinates: boundaryCoordinates ?? this.boundaryCoordinates,
      center: center ?? this.center,
      radiusKm: radiusKm ?? this.radiusKm,
      customDeliveryFee: customDeliveryFee ?? this.customDeliveryFee,
      customMinOrder: customMinOrder ?? this.customMinOrder,
      customDeliveryTime: customDeliveryTime ?? this.customDeliveryTime,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
