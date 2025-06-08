import '../../domain/entities/geofencing/delivery_zone.dart';

/// Helper class for coordinate conversion and zone data insertion
class CoordinateHelper {
  
  /// Convert KML coordinates string to List<LatLng>
  /// 
  /// Input format: "90.2065,25.5138,0 90.2070,25.5145,0 90.2075,25.5142,0"
  /// Output: [LatLng(25.5138, 90.2065), LatLng(25.5145, 90.2070), ...]
  static List<LatLng> convertKMLCoordinates(String kmlCoordinates) {
    final coordinates = <LatLng>[];
    
    try {
      final points = kmlCoordinates.trim().split(' ');
      
      for (final point in points) {
        final coords = point.split(',');
        if (coords.length >= 2) {
          final lng = double.parse(coords[0]);
          final lat = double.parse(coords[1]);
          coordinates.add(LatLng(lat, lng));
        }
      }
    } catch (e) {
      throw FormatException('Invalid KML coordinates format: $e');
    }
    
    return coordinates;
  }

  /// Convert List<LatLng> to Dart code string
  /// 
  /// Output: "const [LatLng(25.5138, 90.2065), LatLng(25.5145, 90.2070), ...]"
  static String coordinatesToDartCode(List<LatLng> coordinates) {
    final buffer = StringBuffer();
    buffer.writeln('const [');
    
    for (int i = 0; i < coordinates.length; i++) {
      final coord = coordinates[i];
      buffer.write('  LatLng(${coord.latitude}, ${coord.longitude})');
      
      if (i < coordinates.length - 1) {
        buffer.write(',');
      }
      buffer.writeln();
    }
    
    buffer.write(']');
    return buffer.toString();
  }

  /// Convert coordinates to JSON format for database storage
  static List<Map<String, double>> coordinatesToJson(List<LatLng> coordinates) {
    return coordinates.map((coord) => {
      'lat': coord.latitude,
      'lng': coord.longitude,
    }).toList();
  }

  /// Convert JSON coordinates back to List<LatLng>
  static List<LatLng> coordinatesFromJson(List<dynamic> jsonCoordinates) {
    return jsonCoordinates.map((coord) {
      final coordMap = coord as Map<String, dynamic>;
      return LatLng(
        coordMap['lat']?.toDouble() ?? 0.0,
        coordMap['lng']?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  /// Validate coordinates are within reasonable bounds
  static bool validateCoordinates(List<LatLng> coordinates) {
    if (coordinates.length < 3) return false;
    
    for (final coord in coordinates) {
      // Check if coordinates are within valid ranges
      if (coord.latitude < -90 || coord.latitude > 90) return false;
      if (coord.longitude < -180 || coord.longitude > 180) return false;
      
      // Check if coordinates are within Northeast India bounds (rough check)
      if (coord.latitude < 20 || coord.latitude > 30) return false;
      if (coord.longitude < 85 || coord.longitude > 100) return false;
    }
    
    return true;
  }

  /// Get bounding box for coordinates
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

  /// Calculate approximate area of polygon in square kilometers
  static double calculatePolygonArea(List<LatLng> coordinates) {
    if (coordinates.length < 3) return 0.0;
    
    // Simplified area calculation using shoelace formula
    // Note: This is approximate and doesn't account for Earth's curvature
    double area = 0.0;
    
    for (int i = 0; i < coordinates.length; i++) {
      int j = (i + 1) % coordinates.length;
      area += coordinates[i].longitude * coordinates[j].latitude;
      area -= coordinates[j].longitude * coordinates[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Convert to approximate square kilometers
    // This is a rough conversion and not precise
    return area * 111.32 * 111.32; // Rough km per degree
  }

  /// Generate SQL INSERT statement for zone data
  static String generateZoneInsertSQL({
    required String zoneName,
    required String townName,
    required String state,
    required int zoneNumber,
    required List<LatLng> coordinates,
    String? description,
  }) {
    final coordsJson = coordinatesToJson(coordinates);
    final coordsJsonString = coordsJson.map((coord) => 
      '{"lat": ${coord['lat']}, "lng": ${coord['lng']}}'
    ).join(', ');
    
    return '''
-- Insert Zone: $zoneName
INSERT INTO zones (
  name, 
  town_id, 
  zone_number, 
  zone_type, 
  boundary_coordinates,
  description,
  is_active
) 
SELECT 
  '$zoneName',
  t.id,
  $zoneNumber,
  'polygon',
  '[$coordsJsonString]'::jsonb,
  '${description ?? 'Delivery zone for $zoneName'}',
  true
FROM towns t 
WHERE t.name = '$townName' AND t.state = '$state';
''';
  }

  /// Print coordinates in various formats for easy copying
  static void printCoordinateFormats(List<LatLng> coordinates, String zoneName) {
    print('\n=== COORDINATE FORMATS FOR $zoneName ===\n');
    
    print('1. DART CODE FORMAT:');
    print(coordinatesToDartCode(coordinates));
    
    print('\n2. JSON FORMAT:');
    print(coordinatesToJson(coordinates));
    
    print('\n3. VALIDATION:');
    print('Valid: ${validateCoordinates(coordinates)}');
    print('Point count: ${coordinates.length}');
    
    final boundingBox = getBoundingBox(coordinates);
    print('Bounding box: $boundingBox');
    
    final area = calculatePolygonArea(coordinates);
    print('Approximate area: ${area.toStringAsFixed(2)} sq km');
    
    print('\n4. SQL INSERT:');
    print(generateZoneInsertSQL(
      zoneName: zoneName,
      townName: 'Tura',
      state: 'Meghalaya',
      zoneNumber: 1,
      coordinates: coordinates,
      description: 'Primary delivery zone covering Main Bazaar and surrounding areas',
    ));
    
    print('\n=== END COORDINATE FORMATS ===\n');
  }
}

/// Extension methods for easier coordinate manipulation
extension CoordinateListExtensions on List<LatLng> {
  /// Check if polygon is closed (first and last points are the same)
  bool get isClosed {
    if (length < 2) return false;
    final first = this.first;
    final last = this.last;
    return (first.latitude - last.latitude).abs() < 0.0001 &&
           (first.longitude - last.longitude).abs() < 0.0001;
  }

  /// Close the polygon by adding the first point at the end
  List<LatLng> get closed {
    if (isClosed) return this;
    return [...this, first];
  }

  /// Get the center point (centroid) of the polygon
  LatLng get center {
    if (isEmpty) return const LatLng(0, 0);
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (final coord in this) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }
    
    return LatLng(sumLat / length, sumLng / length);
  }

  /// Convert to JSON format
  List<Map<String, double>> toJson() {
    return CoordinateHelper.coordinatesToJson(this);
  }

  /// Validate coordinates
  bool get isValid {
    return CoordinateHelper.validateCoordinates(this);
  }
}
