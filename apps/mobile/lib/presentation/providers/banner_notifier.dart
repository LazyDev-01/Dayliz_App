import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/usecases/banner/get_active_banners.dart';
import 'banner_state.dart';

/// Notifier for managing banner state
class BannerNotifier extends StateNotifier<BannerState> {
  final GetActiveBanners getActiveBannersUseCase;

  BannerNotifier({
    required this.getActiveBannersUseCase,
  }) : super(const BannerState());

  /// Load active banners from the repository with cache awareness
  Future<void> loadActiveBanners({bool forceRefresh = false}) async {
    // Don't reload if we already have banners and it's not a forced refresh
    if (!forceRefresh && state.hasBanners && !state.hasError) {
      print('✅ Banners already loaded, skipping reload');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getActiveBannersUseCase(NoParams());

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (banners) => state = state.copyWith(
        isLoading: false,
        banners: banners,
        errorMessage: null,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Set the current banner index
  void setCurrentIndex(int index) {
    if (index >= 0 && index < state.banners.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// Refresh banners (force reload from repository)
  Future<void> refreshBanners() async {
    await loadActiveBanners(forceRefresh: true);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset state to initial state
  void reset() {
    state = const BannerState();
  }

  /// Map failure to user-friendly message
  String _mapFailureToMessage(failure) {
    switch (failure.runtimeType.toString()) {
      case 'ServerFailure':
        return 'Server error occurred. Please try again later.';
      case 'NetworkFailure':
        return 'Network connection error. Please check your internet connection.';
      case 'NotFoundFailure':
        return 'Banners not found.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
