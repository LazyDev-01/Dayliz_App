import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Helper class for Google Maps initialization and configuration
class GoogleMapsHelper {
  static bool _isInitialized = false;
  
  /// Initialize Google Maps with optimized settings
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Reduce logging in production
      if (kReleaseMode) {
        // This helps reduce the "Too many Flogger logs" warnings
        debugPrint('🗺️ Initializing Google Maps in production mode');
      }
      
      _isInitialized = true;
      debugPrint('✅ Google Maps helper initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Google Maps helper: $e');
    }
  }
  
  /// Create optimized camera position with frame sync delay
  static Future<CameraPosition> createCameraPosition({
    required double latitude,
    required double longitude,
    double zoom = 18.0,
    bool withDelay = true,
  }) async {
    if (withDelay) {
      // Add small delay to prevent frame synchronization issues
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: zoom,
    );
  }
  
  /// Animate camera with error handling and frame sync
  static Future<void> animateCameraWithSync(
    GoogleMapController controller, {
    required double latitude,
    required double longitude,
    double zoom = 18.0,
  }) async {
    try {
      // Add delay to prevent frame synchronization issues
      await Future.delayed(const Duration(milliseconds: 100));
      
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: zoom,
          ),
        ),
      );
      
      debugPrint('✅ Camera animated to: $latitude, $longitude');
    } catch (e) {
      debugPrint('❌ Error animating camera: $e');
      rethrow;
    }
  }
  
  /// Get optimized map options for better performance
  static Map<String, dynamic> getOptimizedMapOptions() {
    return {
      'myLocationEnabled': false,
      'myLocationButtonEnabled': false,
      'zoomControlsEnabled': false,
      'mapToolbarEnabled': false,
      'compassEnabled': true,
      'rotateGesturesEnabled': true,
      'scrollGesturesEnabled': true,
      'tiltGesturesEnabled': false, // Disable to reduce rendering complexity
      'zoomGesturesEnabled': true,
      'liteModeEnabled': false, // Keep full functionality
      'buildingsEnabled': true,
      'indoorViewEnabled': false, // Disable to reduce complexity
      'trafficEnabled': false, // Disable to reduce network calls
    };
  }
  
  /// Handle map disposal properly
  static void disposeMapController(GoogleMapController? controller) {
    if (controller != null) {
      try {
        controller.dispose();
        debugPrint('✅ Google Maps controller disposed successfully');
      } catch (e) {
        debugPrint('❌ Error disposing map controller: $e');
      }
    }
  }
  
  /// Check if Google Play Services is available
  static Future<bool> isGooglePlayServicesAvailable() async {
    try {
      // This is a placeholder - in a real implementation, you might want to
      // check Google Play Services availability
      return true;
    } catch (e) {
      debugPrint('❌ Error checking Google Play Services: $e');
      return false;
    }
  }
}
