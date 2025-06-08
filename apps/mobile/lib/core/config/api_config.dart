/// API configuration for external services
class ApiConfig {
  // Google Places API Configuration
  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: 'YOUR_GOOGLE_PLACES_API_KEY_HERE', // TODO: Replace with your actual API key
  );
  
  // Mapbox Configuration (already in use)
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: 'pk.eyJ1IjoiZGF5bGl6IiwiYSI6ImNtYmJ0a244bzB6YXUybHNiaHB1bGI4bDkifQ.ZJdfmD9NbE3zAaDACGtg_g',
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
