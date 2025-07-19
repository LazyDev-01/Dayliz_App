import 'package:flutter/foundation.dart';
import 'delivery_calculation_service.dart';

/// Cached weather service to prevent redundant API calls and improve performance
class CachedWeatherService {
  static CachedWeatherService? _instance;
  static CachedWeatherService get instance => _instance ??= CachedWeatherService._();
  
  CachedWeatherService._();

  // Cache variables
  bool? _cachedWeatherStatus;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 10); // Cache for 10 minutes
  
  // Prevent multiple simultaneous requests
  Future<bool>? _ongoingRequest;

  /// Get weather status with intelligent caching
  Future<bool> getWeatherStatus() async {
    // Check if cache is still valid
    if (_cachedWeatherStatus != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration) {
      debugPrint('CachedWeatherService: Using cached weather status: $_cachedWeatherStatus');
      return _cachedWeatherStatus!;
    }

    // If there's already an ongoing request, wait for it
    if (_ongoingRequest != null) {
      debugPrint('CachedWeatherService: Waiting for ongoing weather request...');
      return await _ongoingRequest!;
    }

    // Start new request
    debugPrint('CachedWeatherService: Fetching fresh weather status...');
    _ongoingRequest = _fetchWeatherStatus();
    
    try {
      final result = await _ongoingRequest!;
      return result;
    } finally {
      _ongoingRequest = null;
    }
  }

  /// Internal method to fetch weather status
  Future<bool> _fetchWeatherStatus() async {
    try {
      final weatherStatus = await DeliveryCalculationService.getCurrentWeatherStatus();
      
      // Update cache
      _cachedWeatherStatus = weatherStatus;
      _lastFetchTime = DateTime.now();
      
      debugPrint('CachedWeatherService: Weather status updated: $weatherStatus');
      return weatherStatus;
    } catch (e) {
      debugPrint('CachedWeatherService: Error fetching weather: $e');
      
      // Return cached value if available, otherwise default to false
      if (_cachedWeatherStatus != null) {
        debugPrint('CachedWeatherService: Using stale cache due to error');
        return _cachedWeatherStatus!;
      }
      
      return false; // Default to normal weather
    }
  }

  /// Force refresh the weather cache
  Future<bool> refreshWeatherStatus() async {
    debugPrint('CachedWeatherService: Force refreshing weather status...');
    _cachedWeatherStatus = null;
    _lastFetchTime = null;
    return await getWeatherStatus();
  }

  /// Clear the weather cache
  void clearCache() {
    debugPrint('CachedWeatherService: Clearing weather cache');
    _cachedWeatherStatus = null;
    _lastFetchTime = null;
    _ongoingRequest = null;
  }

  /// Check if cache is valid
  bool get isCacheValid {
    return _cachedWeatherStatus != null && 
           _lastFetchTime != null && 
           DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  /// Get cached weather status without fetching (returns null if not cached)
  bool? get cachedWeatherStatus => isCacheValid ? _cachedWeatherStatus : null;
}
