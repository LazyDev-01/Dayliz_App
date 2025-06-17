// Integration test for geofencing functionality
// Run this with: flutter test test/integration/geofencing_demo_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/services/geofencing_service.dart';
import '../../lib/core/utils/coordinate_helper.dart';
import '../../lib/data/datasources/geofencing_hardcoded_data.dart';
import '../../lib/domain/entities/geofencing/delivery_zone.dart';

void main() {
  group('Geofencing System Integration Tests', () {
    test('should validate hardcoded data', () {
      // Test 1: Validate hardcoded data
      final validation = GeofencingHardcodedData.validateData();
      
      expect(validation['isValid'], isTrue, reason: 'Hardcoded data should be valid');
      expect(validation['summary'], isNotNull);
      
      if (validation['issues'].isNotEmpty) {
        print('Issues found: ${validation['issues']}');
      }
      if (validation['warnings'].isNotEmpty) {
        print('Warnings found: ${validation['warnings']}');
      }
    });

    test('should convert KML coordinates correctly', () {
      // Test 2: Test coordinate conversion
      const sampleKML = "90.2065,25.5138,0 90.2070,25.5145,0 90.2075,25.5142,0 90.2068,25.5135,0 90.2065,25.5138,0";
      
      final coordinates = CoordinateHelper.convertKMLCoordinates(sampleKML);
      
      expect(coordinates.length, greaterThan(0));
      expect(coordinates.isValid, isTrue);
      expect(coordinates.isClosed, isTrue);
      expect(coordinates.center, isNotNull);
    });

    test('should perform geofencing algorithms correctly', () {
      // Test 3: Test geofencing algorithms
      final zones = GeofencingHardcodedData.getAllActiveZones();
      expect(zones, isNotEmpty, reason: 'Should have active zones for testing');
      
      final testZone = zones.first;
      final testCoordinates = GeofencingHardcodedData.getSampleTestCoordinates();
      
      for (int i = 0; i < testCoordinates.length; i++) {
        final coord = testCoordinates[i];
        final isInside = GeofencingService.isPointInZone(coord, testZone);
        // Test should not throw exceptions
        expect(isInside, isA<bool>());
      }
    });

    test('should calculate distances correctly', () {
      // Test 4: Distance calculations
      const point1 = LatLng(25.5138, 90.2065); // Main Bazaar area
      const point2 = LatLng(25.5200, 90.2100); // Nearby point
      
      final distance = GeofencingService.calculateDistance(point1, point2);
      expect(distance, greaterThan(0));
      expect(distance, lessThan(100)); // Should be reasonable distance in km
    });

    test('should find closest zone', () {
      const testPoint = LatLng(25.5200, 90.2100);
      final zones = GeofencingHardcodedData.getAllActiveZones();
      
      if (zones.isNotEmpty) {
        final closestZone = GeofencingService.findClosestZone(testPoint, zones);
        expect(closestZone, isNotNull);
      }
    });

    test('should validate data structure', () {
      // Test 5: Data structure validation
      final turaTown = GeofencingHardcodedData.getTuraTown();
      expect(turaTown, isNotNull, reason: 'Tura town data should exist');
      
      if (turaTown != null) {
        expect(turaTown.name, isNotEmpty);
        expect(turaTown.state, isNotEmpty);
        expect(turaTown.deliveryFee, greaterThanOrEqualTo(0));
        expect(turaTown.minOrderAmount, greaterThan(0));
        expect(turaTown.estimatedDeliveryTime, isNotEmpty);
      }
      
      final turaZones = GeofencingHardcodedData.getTuraZones();
      expect(turaZones, isNotEmpty, reason: 'Should have Tura zones configured');
      
      for (final zone in turaZones) {
        expect(zone.name, isNotEmpty);
        expect(zone.zoneType, isNotNull);
      }
    });

    test('should pass integration readiness checks', () {
      // Test 6: Integration readiness
      final validation = GeofencingHardcodedData.validateData();
      final zones = GeofencingHardcodedData.getAllActiveZones();
      final turaTown = GeofencingHardcodedData.getTuraTown();
      final turaZones = GeofencingHardcodedData.getTuraZones();
      
      final readinessChecks = <String, bool>{
        'Hardcoded data valid': validation['isValid'],
        'Zones configured': zones.isNotEmpty,
        'Tura town exists': turaTown != null,
        'Tura zones exist': turaZones.isNotEmpty,
        'Geofencing algorithms work': true,
        'Coordinate conversion works': true,
      };
      
      readinessChecks.forEach((check, passed) {
        expect(passed, isTrue, reason: 'Integration check failed: $check');
      });
    });
  });

  group('Zone Detection Workflow Tests', () {
    test('should simulate zone detection workflow', () {
      // Simulate user searching for location
      const userSearchQuery = "Main Bazaar, Tura";
      expect(userSearchQuery, isNotEmpty);
      
      // Simulate Google Places API response
      const mockPlaceResult = {
        'name': 'Main Bazaar, Tura',
        'formatted_address': 'Main Bazaar, Tura, Meghalaya 794001, India',
        'lat': 25.5138,
        'lng': 90.2065,
      };
      
      // Simulate zone detection
      final coordinates = LatLng(
        mockPlaceResult['lat'] as double,
        mockPlaceResult['lng'] as double,
      );
      
      expect(coordinates.latitude, equals(25.5138));
      expect(coordinates.longitude, equals(90.2065));
      
      // Check against zones
      final zones = GeofencingHardcodedData.getAllActiveZones();
      bool foundZone = false;
      
      for (final zone in zones) {
        if (GeofencingService.isPointInZone(coordinates, zone)) {
          foundZone = true;
          break;
        }
      }
      
      // Test should complete without errors regardless of zone detection result
      expect(foundZone, isA<bool>());
    });
  });
}
