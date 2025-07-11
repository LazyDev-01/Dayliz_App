import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/banner_remote_data_source.dart';
import '../../data/repositories/banner_repository_impl.dart';
import '../../domain/repositories/banner_repository.dart';
import '../../domain/usecases/banner/get_active_banners.dart';
import '../../domain/usecases/banner/get_banner_by_id.dart';
import '../../domain/entities/banner.dart';
import 'banner_notifier.dart';
import 'banner_state.dart';

// Data Source Providers
final bannerRemoteDataSourceProvider = Provider<BannerRemoteDataSource>((ref) {
  return BannerRemoteDataSourceImpl(
    supabaseClient: Supabase.instance.client,
  );
});

// Repository Providers
final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepositoryImpl(
    remoteDataSource: ref.watch(bannerRemoteDataSourceProvider),
  );
});

// Use Case Providers
final getActiveBannersUseCaseProvider = Provider<GetActiveBanners>((ref) {
  return GetActiveBanners(ref.watch(bannerRepositoryProvider));
});

final getBannerByIdUseCaseProvider = Provider<GetBannerById>((ref) {
  return GetBannerById(ref.watch(bannerRepositoryProvider));
});

// State Notifier Provider
final bannerNotifierProvider = StateNotifierProvider<BannerNotifier, BannerState>((ref) {
  return BannerNotifier(
    getActiveBannersUseCase: ref.watch(getActiveBannersUseCaseProvider),
  );
});

// Convenience Providers
final bannersProvider = Provider<List<Banner>>((ref) {
  return ref.watch(bannerNotifierProvider).banners;
});

final activeBannersProvider = Provider<List<Banner>>((ref) {
  return ref.watch(bannerNotifierProvider).activeBanners;
});

final bannersLoadingProvider = Provider<bool>((ref) {
  return ref.watch(bannerNotifierProvider).isLoading;
});

final bannersErrorProvider = Provider<String?>((ref) {
  return ref.watch(bannerNotifierProvider).errorMessage;
});

final currentBannerIndexProvider = Provider<int>((ref) {
  return ref.watch(bannerNotifierProvider).currentIndex;
});

final currentBannerProvider = Provider<Banner?>((ref) {
  return ref.watch(bannerNotifierProvider).currentBanner;
});

final hasBannersProvider = Provider<bool>((ref) {
  return ref.watch(bannerNotifierProvider).hasBanners;
});

final hasErrorProvider = Provider<bool>((ref) {
  return ref.watch(bannerNotifierProvider).hasError;
});
