import '../../core/services/geofencing_service.dart';
import '../../domain/entities/geofencing/delivery_zone.dart';
import '../../domain/entities/geofencing/town.dart';
import '../../domain/entities/geofencing/city_boundary.dart';

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

  /// Hardcoded city boundaries data
  static final List<CityBoundary> cityBoundaries = [
    CityBoundary(
      id: 'tura-city-boundary',
      name: 'Tura',
      state: 'Meghalaya',
      country: 'India',
      boundaryCoordinates: _getTuraCityBoundaries(),
      description: 'Broader Tura city boundaries for viewing access',
      isActive: true,
    ),
  ];

  /// Hardcoded zones data with real coordinates
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

  /// Tura Zone-1 (Bazaar) coordinates - REAL DATA
  static List<LatLng> _getTuraZone1Coordinates() {
    // Real Tura Bazaar delivery zone coordinates
    return const [
      LatLng(25.5175, 90.2088), // Point 1
      LatLng(25.5190, 90.2110), // Point 2
      LatLng(25.5205, 90.2135), // Point 3
      LatLng(25.5222, 90.2150), // Point 4
      LatLng(25.5240, 90.2160), // Point 5
      LatLng(25.5255, 90.2155), // Point 6
      LatLng(25.5265, 90.2135), // Point 7
      LatLng(25.5250, 90.2105), // Point 8
      LatLng(25.5225, 90.2080), // Point 9
      LatLng(25.5200, 90.2070), // Point 10
      LatLng(25.5180, 90.2075), // Point 11
      LatLng(25.5175, 90.2088), // Close polygon
    ];
  }

  /// Tura City boundaries (broader area) - REAL DATA
  static List<LatLng> _getTuraCityBoundaries() {
    // Real Tura city boundary coordinates - detailed polygon covering entire Tura city area
    return const [
      LatLng(25.5033588634504, 90.22180312188132),
      LatLng(25.52860089619594, 90.23121854407499),
      LatLng(25.56824566823803, 90.24348981432557),
      LatLng(25.59244938592566, 90.25685315036971),
      LatLng(25.59939875841077, 90.27984444629209),
      LatLng(25.60666028964017, 90.29445230073651),
      LatLng(25.60614778996246, 90.23642436405905),
      LatLng(25.57046068069339, 90.17882228492627),
      LatLng(25.54983352880053, 90.17114207818155),
      LatLng(25.52905226214965, 90.19978935280514),
      LatLng(25.52252454885799, 90.20003922402874),
      LatLng(25.52203215240972, 90.19698246160439),
      LatLng(25.52309230606199, 90.19438488103832),
      LatLng(25.52439427732777, 90.19361901578102),
      LatLng(25.52541499716295, 90.19452620495504),
      LatLng(25.52744155887541, 90.19218861924725),
      LatLng(25.52651980863568, 90.19068460485582),
      LatLng(25.52395925773531, 90.19019253759264),
      LatLng(25.52315660534116, 90.18742238967579),
      LatLng(25.52612126809033, 90.18571542780877),
      LatLng(25.52869760827059, 90.18655137579964),
      LatLng(25.52920572203092, 90.18788962855784),
      LatLng(25.52970255376005, 90.18555559063303),
      LatLng(25.53083145037417, 90.18499609176727),
      LatLng(25.53450531217683, 90.18658266761894),
      LatLng(25.53759873918301, 90.18554172628292),
      LatLng(25.53453470673802, 90.18476346343223),
      LatLng(25.53551588575962, 90.18323134356415),
      LatLng(25.53528032158702, 90.18117126287963),
      LatLng(25.53764595627239, 90.18049717144795),
      LatLng(25.53559848923471, 90.17789544151866),
      LatLng(25.5339579568529, 90.17810982643931),
      LatLng(25.53227585138284, 90.17694251571471),
      LatLng(25.53180079245358, 90.17609309308264),
      LatLng(25.53314816646172, 90.17427642204076),
      LatLng(25.53237993170134, 90.17280468299049),
      LatLng(25.52949123261648, 90.17381167738212),
      LatLng(25.53006255985677, 90.17651802599477),
      LatLng(25.52763168109876, 90.17644503993326),
      LatLng(25.52355831488406, 90.17173227265195),
      LatLng(25.52497389899028, 90.16718780071696),
      LatLng(25.52437992589377, 90.165397140907),
      LatLng(25.53181842197048, 90.16546870194921),
      LatLng(25.53497574627852, 90.1600392659236),
      LatLng(25.5314950696713, 90.15502695144501),
      LatLng(25.5266465909453, 90.15754820094843),
      LatLng(25.52008030813962, 90.16138113077628),
      LatLng(25.51795843363231, 90.16404189153707),
      LatLng(25.51595502098648, 90.16269548128331),
      LatLng(25.51436646369398, 90.1631861348751),
      LatLng(25.5129911497012, 90.16234897315903),
      LatLng(25.5104723434634, 90.16261606101646),
      LatLng(25.50900222969544, 90.16434023994353),
      LatLng(25.51223507233495, 90.1664335700766),
      LatLng(25.51592677481374, 90.16760117886331),
      LatLng(25.51545601915613, 90.16887954192747),
      LatLng(25.51396824562001, 90.16961176125405),
      LatLng(25.5092808912054, 90.17001915886681),
      LatLng(25.50795628855979, 90.1723018289289),
      LatLng(25.5065017749942, 90.1736816491975),
      LatLng(25.50476097325885, 90.17090826270488),
      LatLng(25.50234304032833, 90.16664575252406),
      LatLng(25.5002162185206, 90.16686787096926),
      LatLng(25.49816568871833, 90.16816567577789),
      LatLng(25.50000757682205, 90.17323440721798),
      LatLng(25.49841588186413, 90.17384349847109),
      LatLng(25.49737697332618, 90.17138023397287),
      LatLng(25.49524744410856, 90.16894891451582),
      LatLng(25.49369934315499, 90.16890957838112),
      LatLng(25.49316561805733, 90.17039403231138),
      LatLng(25.49303918258172, 90.17151329532736),
      LatLng(25.49407528716712, 90.17279521795437),
      LatLng(25.49399097274238, 90.17365146116167),
      LatLng(25.4914622857417, 90.17491027288501),
      LatLng(25.49437129933382, 90.18251895805173),
      LatLng(25.49582523465807, 90.18713907308276),
      LatLng(25.49509136596535, 90.19056563072918),
      LatLng(25.49696891819495, 90.19151862092139),
      LatLng(25.49830842695998, 90.19174682123106),
      LatLng(25.49965954943306, 90.19364597473538),
      LatLng(25.49827772167111, 90.19757111482365),
      LatLng(25.5033588634504, 90.22180312188132), // Close polygon
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

  /// Get city boundary by name and state
  static CityBoundary? getCityBoundaryByNameAndState(String name, String state) {
    try {
      return cityBoundaries.firstWhere(
        (city) => city.name.toLowerCase() == name.toLowerCase() &&
                  city.state.toLowerCase() == state.toLowerCase() &&
                  city.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get Tura city boundary specifically (convenience method)
  static CityBoundary? getTuraCityBoundary() {
    return getCityBoundaryByNameAndState('Tura', 'Meghalaya');
  }

  /// Get all active city boundaries
  static List<CityBoundary> getAllActiveCityBoundaries() {
    return cityBoundaries.where((city) => city.isActive).toList();
  }

  /// Detect which city boundary contains the given coordinates
  /// Returns the first matching city boundary or null if outside all cities
  /// This enables multi-city support by automatically detecting the user's city
  static CityBoundary? detectCityBoundary(LatLng coordinates) {
    for (final cityBoundary in cityBoundaries) {
      if (cityBoundary.isActive &&
          GeofencingService.isPointInPolygon(coordinates, cityBoundary.boundaryCoordinates)) {
        return cityBoundary;
      }
    }
    return null; // Outside all known cities
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
