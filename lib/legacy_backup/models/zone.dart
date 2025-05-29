import 'package:equatable/equatable.dart';

class Zone extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double deliveryFee;
  final double minimumOrderAmount;
  final List<List<List<double>>> coordinates; // GeoJSON-like coordinates

  const Zone({
    required this.id,
    required this.name,
    this.description,
    required this.deliveryFee,
    required this.minimumOrderAmount,
    required this.coordinates,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      minimumOrderAmount: (json['minimum_order_amount'] as num).toDouble(),
      coordinates: (json['coordinates'] as List)
          .map((polygon) => (polygon as List)
              .map((point) => (point as List).map((e) => (e as num).toDouble()).toList())
              .toList())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'delivery_fee': deliveryFee,
      'minimum_order_amount': minimumOrderAmount,
      'coordinates': coordinates,
    };
  }

  @override
  List<Object?> get props => [id, name, description, deliveryFee, minimumOrderAmount];

  // Check if a point is inside this zone
  bool containsPoint(double lat, double lng) {
    // Simple implementation - would need a proper point-in-polygon algorithm
    // for production use with complex polygons
    if (coordinates.isEmpty || coordinates[0].isEmpty) {
      return false;
    }
    
    // This is just a placeholder - real implementation would use
    // a proper algorithm to check if the point is inside the polygon
    return true;
  }
} 