import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dayliz_app/services/user_service.dart';

/// Authentication states
enum AuthState {
  /// User is authenticated
  authenticated,
  
  /// User is not authenticated
  unauthenticated,
  
  /// Auth state is being determined
  loading,
  
  /// Authentication state is unknown
  unknown,
}

/// Service that handles authentication operations using Supabase.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  
  late final SupabaseClient _client;
  late final FlutterSecureStorage _secureStorage;
  late final UserService _userService;
  
  /// Stream controller for auth state changes
  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  /// Private constructor
  AuthService._internal();

  /// Initialize the auth service
  Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    
    _client = Supabase.instance.client;
    _secureStorage = const FlutterSecureStorage();
    _userService = UserService.instance;
    
    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn) {
        _authStateController.add(AuthState.authenticated);
        _saveSession(session);
      } else if (event == AuthChangeEvent.signedOut || 
                 event == AuthChangeEvent.userDeleted) {
        _authStateController.add(AuthState.unauthenticated);
        _clearSession();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        _saveSession(session);
      }
    });
    
    // Check initial auth state
    if (_client.auth.currentUser != null) {
      _authStateController.add(AuthState.authenticated);
    } else {
      _authStateController.add(AuthState.unauthenticated);
    }
  }
  
  /// Get the current user
  User? get currentUser => _client.auth.currentUser;
  
  /// Check if user is signed in
  bool get isSignedIn => _client.auth.currentUser != null;
  
  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      await _saveSession(response.session);
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      if (response.user != null) {
        await _saveSession(response.session);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Reset password
  Future<void> resetPassword({
    required String email,
  }) async {
    try {
      debugPrint('🔄 Sending password reset email to: $email');
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: dotenv.env['APP_RESET_PASSWORD_URL'],
      );
      debugPrint('✅ Password reset email sent to: $email');
    } catch (e) {
      debugPrint('❌ Error sending password reset email: $e');
      rethrow;
    }
  }
  
  /// Update password
  Future<void> updatePassword({
    required String password,
    String? accessToken,
  }) async {
    try {
      debugPrint('🔄 Updating password with token');
      
      if (accessToken != null) {
        // Update password using the access token from the reset link
        await _client.auth.updateUser(
          UserAttributes(
            password: password,
          ),
          emailRedirectTo: dotenv.env['APP_REDIRECT_URL'],
        );
        debugPrint('✅ Password updated successfully with token');
      } else if (_client.auth.currentUser != null) {
        // Update password for logged in user
        await _client.auth.updateUser(
          UserAttributes(
            password: password,
          ),
        );
        debugPrint('✅ Password updated successfully for logged in user');
      } else {
        throw Exception('Cannot update password: User not authenticated and no access token provided');
      }
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await _clearSession();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Update user profile
  Future<User?> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(
          data: userData,
        ),
      );
      
      return response.user;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Save session to secure storage
  Future<void> _saveSession(Session? session) async {
    if (session == null) return;
    
    try {
      await _secureStorage.write(
        key: 'access_token',
        value: session.accessToken,
      );
      
      await _secureStorage.write(
        key: 'refresh_token',
        value: session.refreshToken,
      );
      
      // Ensure user exists in public.users table
      if (_client.auth.currentUser != null) {
        await _userService.ensureUserExists();
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }
  
  /// Clear session from secure storage
  Future<void> _clearSession() async {
    try {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }
  
  /// Restore session from secure storage
  Future<bool> restoreSession() async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      
      if (accessToken != null && refreshToken != null) {
        try {
          final response = await _client.auth.recoverSession(accessToken);
          return response.user != null;
        } catch (e) {
          debugPrint('Error recovering session: $e');
          return false;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error restoring session: $e');
      return false;
    }
  }
} 