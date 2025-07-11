import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'delivery_zone.dart';

/// Domain entity representing city boundaries for broader access control
class CityBoundary extends Equatable {
  final String id;
  final String name;
  final String state;
  final String country;
  final List<LatLng> boundaryCoordinates;
  final bool isActive;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CityBoundary({
    required this.id,
    required this.name,
    required this.state,
    required this.country,
    required this.boundaryCoordinates,
    this.isActive = true,
    this.description,
    this.createdAt,
    this.updatedAt,
  }) : assert(boundaryCoordinates.length >= 3, 'City boundary must have at least 3 coordinates');

  /// Check if this city boundary is valid (has enough points and is closed)
  bool get isValidBoundary {
    if (boundaryCoordinates.length < 3) return false;
    
    // Check if polygon is closed (first and last points are the same or very close)
    final first = boundaryCoordinates.first;
    final last = boundaryCoordinates.last;
    
    // Calculate distance between first and last points
    const double earthRadius = 6371000; // meters
    final double latDiff = (last.latitude - first.latitude) * (3.14159 / 180);
    final double lonDiff = (last.longitude - first.longitude) * (3.14159 / 180);
    
    final double a = (latDiff / 2) * (latDiff / 2) +
        (lonDiff / 2) * (lonDiff / 2) *
        math.cos(first.latitude * 3.14159 / 180) *
        math.cos(last.latitude * 3.14159 / 180);

    final double distance = earthRadius * 2 * math.asin(math.sqrt(a));
    
    // If distance is more than 100 meters, polygon might not be properly closed
    return distance < 100; // 100 meters tolerance
  }

  /// Get the center point of the city boundary (approximate)
  LatLng get centerPoint {
    if (boundaryCoordinates.isEmpty) {
      return const LatLng(0, 0);
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final coord in boundaryCoordinates) {
      totalLat += coord.latitude;
      totalLng += coord.longitude;
    }

    return LatLng(
      totalLat / boundaryCoordinates.length,
      totalLng / boundaryCoordinates.length,
    );
  }

  /// Creates a copy of this CityBoundary with the given fields replaced
  CityBoundary copyWith({
    String? id,
    String? name,
    String? state,
    String? country,
    List<LatLng>? boundaryCoordinates,
    bool? isActive,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CityBoundary(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      country: country ?? this.country,
      boundaryCoordinates: boundaryCoordinates ?? this.boundaryCoordinates,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        state,
        country,
        boundaryCoordinates,
        isActive,
        description,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'CityBoundary(id: $id, name: $name, state: $state, country: $country, '
           'coordinates: ${boundaryCoordinates.length} points, isActive: $isActive)';
  }
}
