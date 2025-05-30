import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum for backend types
enum BackendType {
  supabase,
  fastAPI,
}

/// Configuration class for the application
/// Manages environment-specific settings and feature flags
class AppConfig {
  static late SharedPreferences _prefs;
  static const String _useFastAPIKey = 'use_fastapi';
  static const String _useRealGPSKey = 'use_real_gps';

  // Default configuration
  static bool _useFastAPI = false;
  static bool _useRealGPS = true; // Default to real GPS in production
  static String _fastApiBaseUrl = '';
  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';

  /// Initialize the app configuration
  static Future<void> init() async {
    // Load environment variables
    await dotenv.load();

    // Initialize shared preferences
    _prefs = await SharedPreferences.getInstance();

    // Load configuration from environment
    _fastApiBaseUrl = dotenv.env['FASTAPI_BASE_URL'] ?? 'http://localhost:8000';
    _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    // Load feature flags from shared preferences
    _useFastAPI = _prefs.getBool(_useFastAPIKey) ?? false;
    _useRealGPS = _prefs.getBool(_useRealGPSKey) ?? true;
  }

  /// Whether to use FastAPI backend instead of Supabase
  static bool get useFastAPI => _useFastAPI;

  /// Set whether to use FastAPI backend
  static Future<void> setUseFastAPI(bool value) async {
    _useFastAPI = value;
    await _prefs.setBool(_useFastAPIKey, value);
  }

  /// Whether to use real GPS instead of mock GPS
  static bool get useRealGPS => _useRealGPS;

  /// Set whether to use real GPS
  static Future<void> setUseRealGPS(bool value) async {
    _useRealGPS = value;
    await _prefs.setBool(_useRealGPSKey, value);
  }

  // Clean Architecture auth screens are now the default

  /// The base URL for FastAPI backend
  static String get fastApiBaseUrl => _fastApiBaseUrl;

  /// The Supabase URL
  static String get supabaseUrl => _supabaseUrl;

  /// The Supabase anonymous key
  static String get supabaseAnonKey => _supabaseAnonKey;

  /// Check if the app is in development mode
  static bool get isDevelopment {
    // Check if we're running in debug mode
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  /// Toggle development mode
  static Future<void> toggleDevMode() async {
    // Implementation needed
  }

  /// Toggle backend type
  static Future<void> toggleBackend() async {
    // Implementation needed
  }

  /// Set backend type
  static Future<void> setBackend(BackendType backendType) async {
    // Implementation needed
  }
}