import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clean architecture service for Supabase initialization and management
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;

  late final SupabaseClient _client;
  late final FlutterSecureStorage _secureStorage;

  /// Flag to track whether the service has been initialized
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Get the Supabase client
  SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError('SupabaseService must be initialized before accessing client');
    }
    return _client;
  }

  /// Get secure storage instance
  FlutterSecureStorage get secureStorage {
    if (!_isInitialized) {
      throw StateError('SupabaseService must be initialized before accessing secure storage');
    }
    return _secureStorage;
  }

  /// Private constructor
  SupabaseService._internal();

  /// Initialize the Supabase service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SupabaseService: Already initialized, skipping');
      return;
    }

    debugPrint('SupabaseService: Starting initialization');
    debugPrint('SupabaseService: SUPABASE_URL = ${dotenv.env['SUPABASE_URL']}');
    debugPrint('SupabaseService: SUPABASE_ANON_KEY = ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 10)}...');

    try {
      // Check if Supabase is already initialized
      try {
        _client = Supabase.instance.client;
        debugPrint('SupabaseService: Supabase already initialized, using existing client');
      } catch (e) {
        // Supabase not initialized yet, initialize it
        debugPrint('SupabaseService: Supabase not initialized yet, initializing now');

        // CRITICAL FIX: Ensure SharedPreferences is available for Supabase
        try {
          // Try to initialize SharedPreferences to ensure it's available for Supabase
          await SharedPreferences.getInstance();
          debugPrint('SupabaseService: SharedPreferences verified for Supabase');
        } catch (e) {
          debugPrint('SupabaseService: Warning - SharedPreferences not available: $e');
        }

        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
          debug: kDebugMode,
        );
        debugPrint('SupabaseService: Supabase.initialize completed successfully');
        _client = Supabase.instance.client;
      }

      debugPrint('SupabaseService: Supabase client obtained');
      _secureStorage = const FlutterSecureStorage();
      _isInitialized = true;

      debugPrint('SupabaseService: Initialization completed successfully');
    } catch (e) {
      debugPrint('SupabaseService: Error initializing Supabase: $e');
      rethrow;
    }
  }

  /// Check if user is currently authenticated
  bool isAuthenticated() {
    if (!_isInitialized) return false;
    return _client.auth.currentUser != null;
  }

  /// Get current user
  User? getCurrentUser() {
    if (!_isInitialized) return null;
    return _client.auth.currentUser;
  }

  /// Get current session
  Session? getCurrentSession() {
    if (!_isInitialized) return null;
    return _client.auth.currentSession;
  }

  /// Check if session is valid and not expired
  bool isSessionValid() {
    if (!_isInitialized) return false;

    final session = getCurrentSession();
    if (session == null) return false;

    // Check if session is expired
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    return session.expiresAt != null && session.expiresAt! > now;
  }

  /// Refresh the current session
  Future<AuthResponse?> refreshSession() async {
    if (!_isInitialized) return null;

    try {
      final response = await _client.auth.refreshSession();
      debugPrint('SupabaseService: Session refreshed successfully');
      return response;
    } catch (e) {
      debugPrint('SupabaseService: Error refreshing session: $e');
      return null;
    }
  }

  /// Save session data to secure storage
  Future<void> saveSession(Session? session) async {
    if (!_isInitialized || session == null) return;

    try {
      await _secureStorage.write(key: 'refresh_token', value: session.refreshToken);
      await _secureStorage.write(key: 'access_token', value: session.accessToken);
      await _secureStorage.write(key: 'expires_at', value: session.expiresAt.toString());
      await _secureStorage.write(key: 'last_activity', value: DateTime.now().toIso8601String());
      debugPrint('SupabaseService: Session saved to secure storage');
    } catch (e) {
      debugPrint('SupabaseService: Error saving session: $e');
    }
  }

  /// Clear session data from secure storage
  Future<void> clearSession() async {
    if (!_isInitialized) return;

    try {
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'expires_at');
      await _secureStorage.delete(key: 'last_activity');
      debugPrint('SupabaseService: Session cleared from secure storage');
    } catch (e) {
      debugPrint('SupabaseService: Error clearing session: $e');
    }
  }

  /// Update last activity timestamp
  Future<void> updateLastActivity() async {
    if (!_isInitialized) return;

    try {
      await _secureStorage.write(key: 'last_activity', value: DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('SupabaseService: Error updating last activity: $e');
    }
  }

  /// Check if user has been inactive for too long
  Future<bool> checkInactivity({int inactivityTimeoutDays = 7}) async {
    if (!_isInitialized) return false;

    try {
      final lastActivityStr = await _secureStorage.read(key: 'last_activity');
      if (lastActivityStr == null) {
        return false; // No last activity recorded
      }

      final lastActivity = DateTime.parse(lastActivityStr);
      final now = DateTime.now();
      final difference = now.difference(lastActivity);

      return difference.inDays >= inactivityTimeoutDays;
    } catch (e) {
      debugPrint('SupabaseService: Error checking inactivity: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    // Note: We don't dispose the Supabase client as it's a singleton
    // and might be used elsewhere in the app
    debugPrint('SupabaseService: Disposed');
  }
}
