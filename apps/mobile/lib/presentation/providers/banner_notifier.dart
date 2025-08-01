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

  /// Load active banners from the repository
  Future<void> loadActiveBanners() async {
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
      ),
    );
  }

  /// Set the current banner index
  void setCurrentIndex(int index) {
    if (index >= 0 && index < state.banners.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// Refresh banners (reload from repository)
  Future<void> refreshBanners() async {
    await loadActiveBanners();
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
