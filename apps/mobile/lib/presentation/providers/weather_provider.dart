import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/cached_weather_service.dart';

/// Weather state for the application
class WeatherState {
  final bool isBadWeather;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const WeatherState({
    this.isBadWeather = false,
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  WeatherState copyWith({
    bool? isBadWeather,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return WeatherState(
      isBadWeather: isBadWeather ?? this.isBadWeather,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'WeatherState(isBadWeather: $isBadWeather, isLoading: $isLoading, error: $errorMessage)';
  }
}

/// Weather notifier for managing weather state efficiently
class WeatherNotifier extends StateNotifier<WeatherState> {
  final CachedWeatherService _weatherService;

  WeatherNotifier({CachedWeatherService? weatherService})
      : _weatherService = weatherService ?? CachedWeatherService.instance,
        super(const WeatherState());

  /// Get weather status with caching
  Future<void> getWeatherStatus() async {
    // Check if we have a valid cached value first
    final cachedStatus = _weatherService.cachedWeatherStatus;
    if (cachedStatus != null) {
      state = state.copyWith(
        isBadWeather: cachedStatus,
        isLoading: false,
        clearError: true,
      );
      return;
    }

    // Only show loading if we don't have any cached data
    if (state.lastUpdated == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final weatherStatus = await _weatherService.getWeatherStatus();
      
      state = state.copyWith(
        isBadWeather: weatherStatus,
        isLoading: false,
        lastUpdated: DateTime.now(),
        clearError: true,
      );
      
      debugPrint('WeatherProvider: Weather status updated: $weatherStatus');
    } catch (e) {
      debugPrint('WeatherProvider: Error getting weather status: $e');
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get weather status',
      );
    }
  }

  /// Force refresh weather status
  Future<void> refreshWeatherStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final weatherStatus = await _weatherService.refreshWeatherStatus();
      
      state = state.copyWith(
        isBadWeather: weatherStatus,
        isLoading: false,
        lastUpdated: DateTime.now(),
        clearError: true,
      );
      
      debugPrint('WeatherProvider: Weather status refreshed: $weatherStatus');
    } catch (e) {
      debugPrint('WeatherProvider: Error refreshing weather status: $e');
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh weather status',
      );
    }
  }

  /// Initialize weather status (called once during app startup)
  Future<void> initialize() async {
    debugPrint('WeatherProvider: Initializing weather status...');
    await getWeatherStatus();
  }

  /// Clear weather cache
  void clearCache() {
    _weatherService.clearCache();
    state = const WeatherState();
  }

  @override
  void dispose() {
    // PERFORMANCE: Proper disposal of weather service resources
    _weatherService.clearCache();
    super.dispose();
  }
}

/// Weather provider for the application
final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});

/// Convenience provider to get just the weather status boolean
final isWeatherBadProvider = Provider<bool>((ref) {
  return ref.watch(weatherProvider).isBadWeather;
});

/// Provider to check if weather data is loading
final isWeatherLoadingProvider = Provider<bool>((ref) {
  return ref.watch(weatherProvider).isLoading;
});
