import 'package:flutter_test/flutter_test.dart';

import 'package:dayliz_app/presentation/providers/location_gating_provider.dart';

void main() {
  group('LocationGatingState Tests', () {
    test('should create default state correctly', () {
      // Arrange & Act
      const state = LocationGatingState();

      // Assert
      expect(state.status, LocationGatingStatus.notStarted);
      expect(state.isLocationRequired, true);
      expect(state.hasCompletedInSession, false);
      expect(state.canProceedToApp, false);
      expect(state.isServiceAvailable, false);
      expect(state.currentLocationData, null);
      expect(state.zoneDetectionResult, null);
      expect(state.errorMessage, null);
    });

    test('should copy state with new values correctly', () {
      // Arrange
      const originalState = LocationGatingState();

      // Act
      final newState = originalState.copyWith(
        status: LocationGatingStatus.completed,
        hasCompletedInSession: true,
        isLocationRequired: false,
      );

      // Assert
      expect(newState.status, LocationGatingStatus.completed);
      expect(newState.hasCompletedInSession, true);
      expect(newState.isLocationRequired, false);
      // Original values should be preserved
      expect(newState.isLocationPermissionGranted, false);
      expect(newState.currentLocationData, null);
    });

    test('should clear values when specified', () {
      // Arrange
      const originalState = LocationGatingState(
        errorMessage: 'Some error',
        status: LocationGatingStatus.failed,
      );

      // Act
      final newState = originalState.copyWith(
        status: LocationGatingStatus.notStarted,
        clearError: true,
      );

      // Assert
      expect(newState.status, LocationGatingStatus.notStarted);
      expect(newState.errorMessage, null);
    });

    test('should determine canProceedToApp correctly', () {
      // Test case 1: Not completed in session
      const state1 = LocationGatingState(hasCompletedInSession: false);
      expect(state1.canProceedToApp, false);

      // Test case 2: Completed but no zone result
      const state2 = LocationGatingState(hasCompletedInSession: true);
      expect(state2.canProceedToApp, false);

      // Test case 3: Completed with successful zone result would be true
      // (This would require creating a mock ZoneDetectionResult which is complex)
    });

    test('should determine isServiceAvailable correctly', () {
      // Test case 1: No zone result
      const state1 = LocationGatingState();
      expect(state1.isServiceAvailable, false);

      // Test case 2: Zone result would determine availability
      // (This would require creating a mock ZoneDetectionResult which is complex)
    });

    test('should convert to string correctly', () {
      // Arrange
      const state = LocationGatingState(
        status: LocationGatingStatus.completed,
        hasCompletedInSession: true,
      );

      // Act
      final stringRepresentation = state.toString();

      // Assert
      expect(stringRepresentation, contains('LocationGatingState'));
      expect(stringRepresentation, contains('completed'));
      expect(stringRepresentation, contains('canProceed: false')); // No zone result
      expect(stringRepresentation, contains('hasLocation: false')); // No location data
      expect(stringRepresentation, contains('hasZone: false')); // No zone result
    });
  });

  group('LocationGatingStatus Tests', () {
    test('should have all expected status values', () {
      // Assert all enum values exist
      expect(LocationGatingStatus.notStarted, isNotNull);
      expect(LocationGatingStatus.permissionRequesting, isNotNull);
      expect(LocationGatingStatus.locationDetecting, isNotNull);
      expect(LocationGatingStatus.zoneValidating, isNotNull);
      expect(LocationGatingStatus.completed, isNotNull);
      expect(LocationGatingStatus.failed, isNotNull);
      expect(LocationGatingStatus.serviceNotAvailable, isNotNull);
    });
  });
}
