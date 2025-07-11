import 'package:equatable/equatable.dart';
import '../../domain/entities/banner.dart';

/// State class for banner management
class BannerState extends Equatable {
  final List<Banner> banners;
  final bool isLoading;
  final String? errorMessage;
  final int currentIndex;

  const BannerState({
    this.banners = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentIndex = 0,
  });

  /// Create a copy of the state with updated values
  BannerState copyWith({
    List<Banner>? banners,
    bool? isLoading,
    String? errorMessage,
    int? currentIndex,
  }) {
    return BannerState(
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  /// Check if there are banners available
  bool get hasBanners => banners.isNotEmpty;

  /// Check if there's an error
  bool get hasError => errorMessage != null;

  /// Get active banners only
  List<Banner> get activeBanners => banners.where((banner) => banner.isCurrentlyActive).toList();

  /// Check if current index is valid
  bool get isCurrentIndexValid => currentIndex >= 0 && currentIndex < banners.length;

  /// Get current banner if available
  Banner? get currentBanner => isCurrentIndexValid ? banners[currentIndex] : null;

  @override
  List<Object?> get props => [
        banners,
        isLoading,
        errorMessage,
        currentIndex,
      ];

  @override
  String toString() {
    return 'BannerState(banners: ${banners.length}, isLoading: $isLoading, hasError: $hasError, currentIndex: $currentIndex)';
  }
}
