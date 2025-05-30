import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/zone_data_source.dart';
import 'supabase_providers.dart';

/// Provider for the ZoneDataSource
final zoneDataSourceProvider = Provider<ZoneDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ZoneSupabaseDataSource(client: supabaseClient);
});

/// Provider for getting a zone ID based on coordinates
final zoneForCoordinatesProvider = FutureProvider.family<String?, ({double latitude, double longitude})>((ref, coords) async {
  final zoneDataSource = ref.watch(zoneDataSourceProvider);
  return zoneDataSource.getZoneForLocation(coords.latitude, coords.longitude);
});

/// Provider for checking if a location is serviceable
final isLocationServiceableProvider = FutureProvider.family<bool, ({double latitude, double longitude})>((ref, coords) async {
  final zoneDataSource = ref.watch(zoneDataSourceProvider);
  return zoneDataSource.isLocationServiceable(coords.latitude, coords.longitude);
});
