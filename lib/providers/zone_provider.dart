import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/zone.dart';
import 'package:dayliz_app/services/zone_service.dart';
import 'package:flutter/foundation.dart';

/// Provider that fetches all active zones
final zonesProvider = FutureProvider<List<Zone>>((ref) async {
  return await ZoneService.instance.getZones();
});

/// Provider that fetches a zone by ID
final zoneByIdProvider = FutureProvider.family<Zone?, String>((ref, zoneId) async {
  return await ZoneService.instance.getZoneById(zoneId);
});

/// Provider that determines the zone for given coordinates
final zoneForCoordinatesProvider = FutureProvider.family<Zone?, ({double latitude, double longitude})>((ref, coords) async {
  if (coords.latitude == 0 && coords.longitude == 0) {
    return null;
  }
  
  return await ZoneService.instance.getZoneForCoordinates(coords.latitude, coords.longitude);
});

/// Provider class for zone state management
class ZoneNotifier extends StateNotifier<Zone?> {
  final ZoneService _zoneService = ZoneService.instance;
  
  ZoneNotifier() : super(null);
  
  /// Update zone based on coordinates
  Future<void> updateZoneForCoordinates(double latitude, double longitude) async {
    try {
      final zone = await _zoneService.getZoneForCoordinates(latitude, longitude);
      state = zone;
    } catch (e) {
      debugPrint('Error updating zone for coordinates: $e');
      state = null;
    }
  }
  
  /// Clear current zone
  void clearZone() {
    state = null;
  }
}

/// Provider for active zone state
final activeZoneProvider = StateNotifierProvider<ZoneNotifier, Zone?>((ref) {
  return ZoneNotifier();
}); 