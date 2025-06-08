import 'dart:math' as math;
import '../../domain/entities/geofencing/delivery_zone.dart';

/// Service for geofencing calculations and zone detection
class GeofencingService {
  /// Check if a point is inside a delivery zone
  static bool isPointInZone(LatLng userLocation, DeliveryZone zone) {
    if (!zone.isActive) return false;

    switch (zone.zoneType) {
      case ZoneType.polygon:
        return _isPointInPolygon(userLocation, zone.boundaryCoordinates!);
      case ZoneType.circle:
        return _isPointInCircle(userLocation, zone.center!, zone.radiusKm!);
    }
  }

  /// Check if a point is inside a polygon using ray casting algorithm
  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    int intersections = 0;
    
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      
      final LatLng vertex1 = polygon[i];
      final LatLng vertex2 = polygon[j];
      
      // Check if point is on the same horizontal line as the edge
      if (((vertex1.latitude > point.latitude) != (vertex2.latitude > point.latitude)) &&
          (point.longitude < (vertex2.longitude - vertex1.longitude) * 
           (point.latitude - vertex1.latitude) / 
           (vertex2.latitude - vertex1.latitude) + vertex1.longitude)) {
        intersections++;
      }
    }
    
    // Point is inside if number of intersections is odd
    return intersections % 2 == 1;
  }

  /// Check if a point is inside a circle using Haversine distance
  static bool _isPointInCircle(LatLng point, LatLng center, double radiusKm) {
    final double distance = calculateDistance(point, center);
    return distance <= radiusKm;
  }

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadiusKm = 6371.0;
    
    final double lat1Rad = _degreesToRadians(point1.latitude);
    final double lat2Rad = _degreesToRadians(point2.latitude);
    final double deltaLatRad = _degreesToRadians(point2.latitude - point1.latitude);
    final double deltaLngRad = _degreesToRadians(point2.longitude - point1.longitude);
    
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Find the closest zone to a point (even if point is outside all zones)
  static DeliveryZone? findClosestZone(LatLng userLocation, List<DeliveryZone> zones) {
    if (zones.isEmpty) return null;

    DeliveryZone? closestZone;
    double minDistance = double.infinity;

    for (final zone in zones) {
      if (!zone.isActive) continue;

      double distance;
      
      if (zone.isCircle && zone.center != null) {
        // For circular zones, use distance to center
        distance = calculateDistance(userLocation, zone.center!);
      } else if (zone.isPolygon && zone.boundaryCoordinates != null) {
        // For polygon zones, find distance to closest boundary point
        distance = _distanceToPolygon(userLocation, zone.boundaryCoordinates!);
      } else {
        continue;
      }

      if (distance < minDistance) {
        minDistance = distance;
        closestZone = zone;
      }
    }

    return closestZone;
  }

  /// Calculate minimum distance from a point to a polygon boundary
  static double _distanceToPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.isEmpty) return double.infinity;

    double minDistance = double.infinity;

    // Check distance to each vertex
    for (final vertex in polygon) {
      final distance = calculateDistance(point, vertex);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // Check distance to each edge (simplified - using vertex distances)
    // For more accuracy, you could implement point-to-line-segment distance
    
    return minDistance;
  }

  /// Get the center point of a polygon (centroid calculation)
  static LatLng getPolygonCenter(List<LatLng> polygon) {
    if (polygon.isEmpty) return const LatLng(0, 0);
    if (polygon.length == 1) return polygon.first;

    double sumLat = 0;
    double sumLng = 0;

    for (final point in polygon) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(
      sumLat / polygon.length,
      sumLng / polygon.length,
    );
  }

  /// Check if a polygon is valid (has at least 3 points and is properly closed)
  static bool isValidPolygon(List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    
    // Check if polygon is closed (first and last points are the same or very close)
    final first = polygon.first;
    final last = polygon.last;
    final distance = calculateDistance(first, last);
    
    // If distance is more than 10 meters, polygon might not be properly closed
    return distance < 0.01; // ~10 meters
  }

  /// Validate a circular zone
  static bool isValidCircle(LatLng center, double radiusKm) {
    // Check if coordinates are valid
    if (center.latitude < -90 || center.latitude > 90) return false;
    if (center.longitude < -180 || center.longitude > 180) return false;
    
    // Check if radius is reasonable (between 0.1km and 50km)
    return radiusKm > 0.1 && radiusKm <= 50.0;
  }

  /// Get bounding box for a list of coordinates
  static Map<String, double> getBoundingBox(List<LatLng> coordinates) {
    if (coordinates.isEmpty) {
      return {'minLat': 0, 'maxLat': 0, 'minLng': 0, 'maxLng': 0};
    }

    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (final coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  /// Check if a point is within a bounding box (for quick filtering)
  static bool isPointInBoundingBox(LatLng point, Map<String, double> boundingBox) {
    return point.latitude >= boundingBox['minLat']! &&
           point.latitude <= boundingBox['maxLat']! &&
           point.longitude >= boundingBox['minLng']! &&
           point.longitude <= boundingBox['maxLng']!;
  }
}
