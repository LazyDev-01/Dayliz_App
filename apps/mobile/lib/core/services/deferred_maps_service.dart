import 'package:flutter/foundation.dart';

/// Service for managing lazy Google Maps loading
/// This improves perceived performance by showing loading states
class MapsLoaderService {
  static final MapsLoaderService _instance = MapsLoaderService._internal();
  factory MapsLoaderService() => _instance;
  MapsLoaderService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Check if Maps service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if Maps service is currently initializing
  bool get isInitializing => _isInitializing;

  /// Initialize Maps service with loading delay for better UX
  Future<bool> initializeMaps() async {
    if (_isInitialized) {
      debugPrint('🗺️ Maps service already initialized');
      return true;
    }

    if (_isInitializing) {
      debugPrint('🗺️ Maps initialization in progress, waiting...');
      // Wait for current initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    try {
      _isInitializing = true;
      debugPrint('🗺️ Initializing Maps service...');

      final stopwatch = Stopwatch()..start();

      // Add a small delay to show loading state (improves perceived performance)
      await Future.delayed(const Duration(milliseconds: 300));

      // In a real implementation, this could:
      // 1. Pre-warm the Maps engine
      // 2. Load map tiles
      // 3. Initialize location services
      // 4. Check API keys

      stopwatch.stop();

      _isInitialized = true;
      _isInitializing = false;

      debugPrint('✅ Maps service initialized in ${stopwatch.elapsedMilliseconds}ms');
      return true;
    } catch (e) {
      _isInitializing = false;
      debugPrint('❌ Failed to initialize Maps service: $e');
      return false;
    }
  }

  /// Reset the service (for testing purposes)
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _isInitializing = false;
  }
}
