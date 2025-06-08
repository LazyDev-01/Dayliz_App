import '../../domain/entities/geofencing/delivery_zone.dart';
import '../../domain/entities/geofencing/town.dart';

/// Hardcoded geofencing data for fast startup and offline fallback
class GeofencingHardcodedData {
  
  /// Hardcoded towns data
  static const List<Town> towns = [
    Town(
      id: 'tura-meghalaya-001',
      name: 'Tura',
      state: 'Meghalaya',
      country: 'India',
      deliveryFee: 25,
      minOrderAmount: 200,
      estimatedDeliveryTime: '30-45 mins',
      currency: 'INR',
      isActive: true,
      launchDate: null, // Will be set when you launch
    ),
  ];

  /// Hardcoded zones data - PLACEHOLDER COORDINATES
  /// Replace with your actual Zone-1 coordinates from Google My Maps
  static final List<DeliveryZone> zones = [
    DeliveryZone(
      id: 'tura-zone-1-main-bazaar',
      name: 'Zone-1 Main Bazaar Area',
      townId: 'tura-meghalaya-001',
      zoneNumber: 1,
      zoneType: ZoneType.polygon,
      boundaryCoordinates: _getTuraZone1Coordinates(),
      description: 'Primary delivery zone covering Main Bazaar and surrounding 5-6 areas in Tura',
      isActive: true,
      priority: 1,
    ),
  ];

  /// PLACEHOLDER: Tura Zone-1 coordinates
  /// TODO: Replace with actual coordinates from Google My Maps
  static List<LatLng> _getTuraZone1Coordinates() {
    // These are PLACEHOLDER coordinates around Tura area
    // Replace with your actual Zone-1 boundary coordinates
    return const [
      LatLng(25.5138, 90.2065), // Point 1 - PLACEHOLDER
      LatLng(25.5145, 90.2070), // Point 2 - PLACEHOLDER  
      LatLng(25.5142, 90.2075), // Point 3 - PLACEHOLDER
      LatLng(25.5135, 90.2068), // Point 4 - PLACEHOLDER
      LatLng(25.5138, 90.2065), // Close polygon - PLACEHOLDER
    ];
  }

  /// Get town by name and state
  static Town? getTownByNameAndState(String name, String state) {
    try {
      return towns.firstWhere(
        (town) => town.name.toLowerCase() == name.toLowerCase() && 
                  town.state.toLowerCase() == state.toLowerCase() &&
                  town.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get zones for a specific town
  static List<DeliveryZone> getZonesForTown(String townId) {
    return zones.where((zone) => zone.townId == townId && zone.isActive).toList();
  }

  /// Get all active zones
  static List<DeliveryZone> getAllActiveZones() {
    return zones.where((zone) => zone.isActive).toList();
  }

  /// Get zone by ID
  static DeliveryZone? getZoneById(String zoneId) {
    try {
      return zones.firstWhere((zone) => zone.id == zoneId);
    } catch (e) {
      return null;
    }
  }

  /// Check if hardcoded data is available for a town
  static bool hasDataForTown(String name, String state) {
    return getTownByNameAndState(name, state) != null;
  }

  /// Get Tura town specifically (convenience method)
  static Town? getTuraTown() {
    return getTownByNameAndState('Tura', 'Meghalaya');
  }

  /// Get Tura zones specifically (convenience method)
  static List<DeliveryZone> getTuraZones() {
    final turaTown = getTuraTown();
    if (turaTown == null) return [];
    return getZonesForTown(turaTown.id);
  }

  /// Update Zone-1 coordinates (call this when you have real coordinates)
  static void updateTuraZone1Coordinates(List<LatLng> newCoordinates) {
    // Find Zone-1 and update its coordinates
    final zoneIndex = zones.indexWhere((zone) => zone.id == 'tura-zone-1-main-bazaar');
    if (zoneIndex != -1) {
      zones[zoneIndex] = zones[zoneIndex].copyWith(
        boundaryCoordinates: newCoordinates,
      );
    }
  }

  /// Validate that all hardcoded data is properly configured
  static Map<String, dynamic> validateData() {
    final issues = <String>[];
    final warnings = <String>[];

    // Check towns
    if (towns.isEmpty) {
      issues.add('No towns configured');
    }

    for (final town in towns) {
      if (town.deliveryFee <= 0) {
        warnings.add('Town ${town.name} has invalid delivery fee');
      }
      if (town.minOrderAmount <= 0) {
        warnings.add('Town ${town.name} has invalid min order amount');
      }
    }

    // Check zones
    if (zones.isEmpty) {
      issues.add('No zones configured');
    }

    for (final zone in zones) {
      if (zone.isPolygon && (zone.boundaryCoordinates == null || zone.boundaryCoordinates!.length < 3)) {
        issues.add('Zone ${zone.name} has invalid polygon coordinates');
      }
      if (zone.isCircle && (zone.center == null || zone.radiusKm == null || zone.radiusKm! <= 0)) {
        issues.add('Zone ${zone.name} has invalid circle configuration');
      }
      
      // Check if town exists for this zone
      final townExists = towns.any((town) => town.id == zone.townId);
      if (!townExists) {
        issues.add('Zone ${zone.name} references non-existent town ${zone.townId}');
      }
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'summary': {
        'towns': towns.length,
        'zones': zones.length,
        'activeTowns': towns.where((t) => t.isActive).length,
        'activeZones': zones.where((z) => z.isActive).length,
      }
    };
  }

  /// Get sample coordinates for testing (around Tura area)
  static List<LatLng> getSampleTestCoordinates() {
    return const [
      LatLng(25.5140, 90.2067), // Inside Zone-1 (should be detected)
      LatLng(25.5200, 90.2100), // Outside Zone-1 (should not be detected)
      LatLng(25.5100, 90.2050), // Edge case coordinate
    ];
  }
}

/// Extension methods for easier data access
extension GeofencingHardcodedDataExtensions on GeofencingHardcodedData {
  /// Quick access to Tura data
  static Map<String, dynamic> getTuraData() {
    final town = GeofencingHardcodedData.getTuraTown();
    final zones = GeofencingHardcodedData.getTuraZones();
    
    return {
      'town': town,
      'zones': zones,
      'hasData': town != null && zones.isNotEmpty,
      'zoneCount': zones.length,
    };
  }
}
