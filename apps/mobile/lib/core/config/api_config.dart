/// API configuration for external services
class ApiConfig {
  // Google Places API Configuration
  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '', // Will be configured via environment variables
  );
  
  // Cost Control Settings
  static const Map<String, int> placesApiLimits = {
    'maxRequestsPerMinute': 10,
    'maxRequestsPerHour': 100,
    'maxRequestsPerDay': 500,
  };
  
  // Regional Settings
  static const String defaultRegion = 'IN'; // India
  static const String defaultLanguage = 'en'; // English
  
  /// Check if Google Places API is properly configured
  static bool get isGooglePlacesConfigured {
    return googlePlacesApiKey.isNotEmpty && 
           googlePlacesApiKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE';
  }
  
  /// Get environment-specific settings
  static bool get isProduction {
    return const bool.fromEnvironment('dart.vm.product');
  }
  
  /// Get debug mode status
  static bool get isDebugMode {
    return !isProduction;
  }
}
