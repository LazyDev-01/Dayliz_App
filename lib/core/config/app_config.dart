import 'dart:async';
import 'package:flutter/foundation.dart';
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

  // Default configuration
  static bool _useFastAPI = false;
  static String _fastApiBaseUrl = '';
  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';

  /// Initialize the app configuration
  static Future<void> init() async {
    // Load environment variables
    await dotenv.load();

    // CRITICAL FIX: Skip SharedPreferences initialization to prevent blocking
    // We'll initialize it later when actually needed
    debugPrint('Skipping SharedPreferences in AppConfig to prevent blocking');

    // Load configuration from environment
    _fastApiBaseUrl = dotenv.env['FASTAPI_BASE_URL'] ?? 'http://localhost:8000';
    _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    // CRITICAL FIX: Use default value for feature flags instead of reading from SharedPreferences
    _useFastAPI = false; // Default to false, will be loaded later when SharedPreferences is fixed

    debugPrint('AppConfig initialized successfully (without SharedPreferences)');
  }

  /// Whether to use FastAPI backend instead of Supabase
  static bool get useFastAPI => _useFastAPI;

  /// Set whether to use FastAPI backend
  static Future<void> setUseFastAPI(bool value) async {
    _useFastAPI = value;
    await _prefs.setBool(_useFastAPIKey, value);
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