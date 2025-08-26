import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/zone_data_source.dart';
import '../../data/datasources/zone_remote_data_source.dart';
import '../../data/repositories/zone_repository_impl.dart';
import '../../domain/repositories/zone_repository.dart';
import '../../domain/entities/zone.dart';
import '../../core/network/network_info.dart';
import 'supabase_providers.dart';
import 'network_providers.dart';

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

/// Provider for the ZoneRepository
final zoneRepositoryProvider = Provider<ZoneRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final remoteDataSource = ZoneSupabaseRemoteDataSource(client: supabaseClient);
  final networkInfo = ref.watch(networkInfoProvider);
  return ZoneRepositoryImpl(
    remoteDataSource: remoteDataSource,
    networkInfo: networkInfo,
  );
});

/// Provider for getting a Zone object based on coordinates
final zoneObjectForCoordinatesProvider = FutureProvider.family<Zone?, ({double latitude, double longitude})>((ref, coords) async {
  final zoneRepository = ref.watch(zoneRepositoryProvider);
  final result = await zoneRepository.getZoneForLocation(coords.latitude, coords.longitude);
  return result.fold(
    (failure) => null, // Return null on failure
    (zone) => zone,    // Return the zone on success
  );
});
