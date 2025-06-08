import 'package:equatable/equatable.dart';

/// Represents a coordinate point with latitude and longitude
class LatLng extends Equatable {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  List<Object> get props => [latitude, longitude];

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
  };

  /// Create from JSON map
  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
    json['lat']?.toDouble() ?? 0.0,
    json['lng']?.toDouble() ?? 0.0,
  );
}

/// Enum for different zone types
enum ZoneType {
  polygon,
  circle;

  String get value {
    switch (this) {
      case ZoneType.polygon:
        return 'polygon';
      case ZoneType.circle:
        return 'circle';
    }
  }

  static ZoneType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'polygon':
        return ZoneType.polygon;
      case 'circle':
        return ZoneType.circle;
      default:
        throw ArgumentError('Unknown zone type: $value');
    }
  }
}

/// Domain entity representing a delivery zone with geofencing capabilities
class DeliveryZone extends Equatable {
  final String id;
  final String name;
  final String townId;
  final int zoneNumber;
  
  // Geofencing data
  final ZoneType zoneType;
  
  // For polygon zones
  final List<LatLng>? boundaryCoordinates;
  
  // For circular zones
  final LatLng? center;
  final double? radiusKm;
  
  // Zone-specific settings (optional overrides)
  final int? customDeliveryFee;
  final int? customMinOrder;
  final String? customDeliveryTime;
  
  // Status and metadata
  final bool isActive;
  final int priority;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DeliveryZone({
    required this.id,
    required this.name,
    required this.townId,
    required this.zoneNumber,
    required this.zoneType,
    this.boundaryCoordinates,
    this.center,
    this.radiusKm,
    this.customDeliveryFee,
    this.customMinOrder,
    this.customDeliveryTime,
    required this.isActive,
    this.priority = 1,
    this.description,
    this.createdAt,
    this.updatedAt,
  }) : assert(
         (zoneType == ZoneType.polygon && boundaryCoordinates != null) ||
         (zoneType == ZoneType.circle && center != null && radiusKm != null),
         'Zone must have appropriate coordinates for its type'
       );

  @override
  List<Object?> get props => [
        id,
        name,
        townId,
        zoneNumber,
        zoneType,
        boundaryCoordinates,
        center,
        radiusKm,
        customDeliveryFee,
        customMinOrder,
        customDeliveryTime,
        isActive,
        priority,
        description,
        createdAt,
        updatedAt,
      ];

  /// Creates a copy of this DeliveryZone with the given fields replaced
  DeliveryZone copyWith({
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
    return DeliveryZone(
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

  /// Check if this zone is a polygon zone
  bool get isPolygon => zoneType == ZoneType.polygon;

  /// Check if this zone is a circular zone
  bool get isCircle => zoneType == ZoneType.circle;

  /// Get the display name for the zone
  String get displayName => '$name (Zone $zoneNumber)';

  @override
  String toString() {
    return 'DeliveryZone(id: $id, name: $name, zoneNumber: $zoneNumber, type: ${zoneType.value}, isActive: $isActive)';
  }
}
