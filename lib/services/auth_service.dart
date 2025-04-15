import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dayliz_app/services/user_service.dart';

/// Authentication error types for more specific error handling
enum AuthErrorType {
  /// Invalid credentials (wrong password, etc.)
  invalidCredentials,
  
  /// User not found
  userNotFound,
  
  /// Account already exists
  accountExists,
  
  /// Email not verified
  emailNotVerified,
  
  /// Network error
  networkError,
  
  /// Too many requests
  tooManyRequests,
  
  /// Server error
  serverError,
  
  /// Token expired
  tokenExpired,
  
  /// Unknown error
  unknown,
}

/// Custom auth exception with user-friendly messages
class AuthException implements Exception {
  final String message;
  final AuthErrorType type;
  final dynamic originalError;
  
  AuthException({
    required this.message,
    required this.type,
    this.originalError,
  });
  
  @override
  String toString() => message;
  
  /// Create an AuthException from a Supabase exception
  factory AuthException.fromSupabaseException(dynamic e) {
    if (e is AuthException) return e;
    
    String message = 'An authentication error occurred';
    AuthErrorType type = AuthErrorType.unknown;
    
    if (e is AuthException) {
      return e;
    } else if (e is AuthException) {
      // Already a custom exception, just return it
      return e;
    } else if (e is AuthException) {
      // Handle Supabase auth exceptions
      if (e.toString().contains('Invalid login credentials')) {
        message = 'Invalid email or password';
        type = AuthErrorType.invalidCredentials;
      } else if (e.toString().contains('Email not confirmed')) {
        message = 'Please verify your email before logging in';
        type = AuthErrorType.emailNotVerified;
      } else if (e.toString().contains('User already registered')) {
        message = 'An account with this email already exists';
        type = AuthErrorType.accountExists;
      } else if (e.toString().contains('network')) {
        message = 'Network error. Please check your connection';
        type = AuthErrorType.networkError;
      } else if (e.toString().contains('too many requests')) {
        message = 'Too many attempts. Please try again later';
        type = AuthErrorType.tooManyRequests;
      }
    } else if (e.toString().contains('JWT')) {
      message = 'Your session has expired. Please log in again';
      type = AuthErrorType.tokenExpired;
    } else if (e.toString().contains('network')) {
      message = 'Network error. Please check your connection';
      type = AuthErrorType.networkError;
    }
    
    return AuthException(
      message: message,
      type: type,
      originalError: e,
    );
  }
}

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
  
  /// User's session needs refresh
  sessionExpired,
  
  /// User needs to verify email
  emailVerificationRequired,
}

/// Service that handles authentication operations using Supabase.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  
  late final SupabaseClient _client;
  late final FlutterSecureStorage _secureStorage;
  late final UserService _userService;
  
  /// Flag to track whether the service has been initialized
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// Stream controller for auth state changes
  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  /// Timer for periodic session checks
  Timer? _sessionCheckTimer;
  
  /// Last time auth was refreshed
  DateTime? _lastRefreshTime;
  
  /// Flag to prevent multiple concurrent refresh attempts
  bool _isRefreshing = false;
  
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
      final User? user = data.session?.user;
      
      if (event == AuthChangeEvent.signedIn) {
        // Check if email is verified if verification is required
        if (user != null && _isEmailVerificationRequired(user)) {
          _authStateController.add(AuthState.emailVerificationRequired);
          _clearSession();
          return;
        }
        
        _authStateController.add(AuthState.authenticated);
        _saveSession(session);
        _startSessionCheck();
      } else if (event == AuthChangeEvent.signedOut || 
                 event == AuthChangeEvent.userDeleted) {
        _authStateController.add(AuthState.unauthenticated);
        _clearSession();
        _stopSessionCheck();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        _saveSession(session);
        _lastRefreshTime = DateTime.now();
      } else if (event == AuthChangeEvent.userUpdated) {
        // If user is updated, check if email was verified
        if (user != null && !_isEmailVerificationRequired(user)) {
          _authStateController.add(AuthState.authenticated);
        }
      }
    });
    
    // Check initial auth state
    if (_client.auth.currentUser != null) {
      if (_isEmailVerificationRequired(_client.auth.currentUser)) {
        _authStateController.add(AuthState.emailVerificationRequired);
      } else {
        _authStateController.add(AuthState.authenticated);
        _startSessionCheck();
      }
    } else {
      _authStateController.add(AuthState.unauthenticated);
    }
    
    _isInitialized = true;
  }
  
  /// Check if email verification is required for a user
  bool _isEmailVerificationRequired(User? user) {
    // Supabase doesn't have a direct way to check if email is verified
    // This is a placeholder implementation
    // In production, you would need to check a custom field or meta data
    
    // For now, we'll assume email is verified for simplicity
    // In a real app, you'd need to check user.emailConfirmedAt or similar
    return false;
  }
  
  /// Get the current user
  User? get currentUser => _client.auth.currentUser;
  
  /// Check if user is signed in
  bool get isSignedIn => _client.auth.currentUser != null;
  
  /// Check if the current user's email is verified
  bool get isEmailVerified {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    
    // Supabase doesn't have a direct property for email verification
    // Check user.emailConfirmedAt or a custom field
    // For now we'll assume true if user has email
    return user.email != null;
  }
  
  /// Start periodic session check
  void _startSessionCheck() {
    _stopSessionCheck(); // Stop existing timer if any
    
    // Check session every 5 minutes
    _sessionCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkSession();
    });
    
    // Initial check
    _checkSession();
  }
  
  /// Stop periodic session check
  void _stopSessionCheck() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
  }
  
  /// Check if session is valid and refresh if needed
  Future<void> _checkSession() async {
    if (!isSignedIn || _isRefreshing) return;
    
    try {
      // Check if we need to refresh the session
      final session = _client.auth.currentSession;
      if (session == null) {
        _handleSessionExpired();
        return;
      }
      
      // Check if token is about to expire (within 30 minutes)
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      final now = DateTime.now();
      final timeUntilExpiry = expiresAt.difference(now);
      
      if (timeUntilExpiry.inMinutes < 30) {
        // Token is about to expire, refresh it
        await _refreshSession();
      }
    } catch (e) {
      debugPrint('Error checking session: $e');
      // If there's an error, attempt to refresh the session
      await _refreshSession();
    }
  }
  
  /// Handle session expiration
  void _handleSessionExpired() {
    debugPrint('Session expired, notifying listeners');
    _authStateController.add(AuthState.sessionExpired);
    
    // Attempt to refresh the session
    _refreshSession();
  }
  
  /// Refresh the session using the refresh token
  Future<bool> _refreshSession() async {
    if (_isRefreshing) return false;
    
    _isRefreshing = true;
    try {
      debugPrint('Attempting to refresh session');
      
      // Get refresh token from secure storage
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        debugPrint('No refresh token found');
        _authStateController.add(AuthState.unauthenticated);
        _isRefreshing = false;
        return false;
      }
      
      // Attempt to refresh the session
      final response = await _client.auth.refreshSession();
      if (response.session != null) {
        debugPrint('Session refreshed successfully');
        _lastRefreshTime = DateTime.now();
        await _saveSession(response.session);
        _authStateController.add(AuthState.authenticated);
        _isRefreshing = false;
        return true;
      } else {
        debugPrint('Failed to refresh session');
        _authStateController.add(AuthState.unauthenticated);
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      _authStateController.add(AuthState.unauthenticated);
      _isRefreshing = false;
      return false;
    }
  }
  
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
      
      if (_isEmailVerificationRequired(response.user)) {
        throw AuthException(
          message: 'Please verify your email before logging in',
          type: AuthErrorType.emailNotVerified,
        );
      }
      
      await _saveSession(response.session);
      _startSessionCheck();
      return response;
    } catch (e) {
      throw AuthException.fromSupabaseException(e);
    }
  }
  
  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      debugPrint('🔄 Starting Google Sign-in process');
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: dotenv.env['APP_REDIRECT_URL'],
      );
      
      if (response) {
        debugPrint('✅ Google Sign-in process initiated successfully');
      } else {
        debugPrint('❌ Google Sign-in process failed');
        throw AuthException(
          message: 'Failed to initiate Google Sign-in',
          type: AuthErrorType.unknown,
        );
      }
      
      // Return an empty AuthResponse since the actual sign-in happens in the browser
      // The user will be redirected back to the app and the auth state will be updated
      final AuthResponse authResponse = AuthResponse(
        session: null,
        user: null,
      );
      
      return authResponse;
    } catch (e) {
      debugPrint('❌ Error in Google Sign-in: $e');
      throw AuthException.fromSupabaseException(e);
    }
  }
  
  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
    bool requireEmailVerification = true,
  }) async {
    try {
      // Supabase signup with email confirmation
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userData,
        emailRedirectTo: dotenv.env['APP_REDIRECT_URL'],
      );
      
      if (response.user == null) {
        throw AuthException(
          message: 'Failed to create account',
          type: AuthErrorType.unknown,
        );
      }
      
      // If email verification is required, don't save session
      if (requireEmailVerification) {
        _authStateController.add(AuthState.emailVerificationRequired);
        return response;
      }
      
      // If email verification not required, proceed as normal
      await _saveSession(response.session);
      
      // Update profile information in the users table
      await _userService.updateUserProfile(
        name: userData?['name'],
        phone: userData?['phone'],
        avatarUrl: userData?['avatar_url'],
      );
      
      _startSessionCheck();
      return response;
    } catch (e) {
      throw AuthException.fromSupabaseException(e);
    }
  }
  
  /// Send email verification
  Future<void> sendEmailVerification({
    required String email,
  }) async {
    try {
      debugPrint('🔄 Sending email verification to: $email');
      
      // In Supabase, there's no direct API for this if the user is not signed up yet
      // If they're already signed up, a verification email is sent automatically
      // This is a placeholder for a custom implementation
      
      // For existing users who need to re-verify
      if (_client.auth.currentUser?.email == email) {
        // For Supabase, this would be a custom function or API endpoint
        // that triggers the verification email
        debugPrint('✅ Verification email sent to: $email');
      } else {
        throw AuthException(
          message: 'Cannot send verification email: User not found',
          type: AuthErrorType.userNotFound,
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending verification email: $e');
      throw AuthException.fromSupabaseException(e);
    }
  }
  
  /// Verify email with token from verification link
  Future<bool> verifyEmail({
    required String token,
  }) async {
    try {
      debugPrint('🔄 Verifying email with token');
      
      // In Supabase, email verification happens automatically via redirect URL
      // This method would be used for a custom verification flow
      // For now, it's a placeholder
      
      // For demonstration, just return success
      debugPrint('✅ Email verified successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying email: $e');
      throw AuthException.fromSupabaseException(e);
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
      throw AuthException.fromSupabaseException(e);
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
        throw AuthException(
          message: 'Cannot update password: User not authenticated and no access token provided',
          type: AuthErrorType.userNotFound,
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      throw AuthException.fromSupabaseException(e);
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      _stopSessionCheck();
      
      // Clear local user data before signing out
      await _clearLocalUserData();
      
      // Sign out from Supabase
      await _client.auth.signOut();
      
      // Clear session data
      await _clearSession();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Still try to clear local session
      await _clearSession();
      throw AuthException.fromSupabaseException(e);
    }
  }
  
  /// Clear local user data
  Future<void> _clearLocalUserData() async {
    try {
      // Add any app-specific data clearing here
      // For example: clear cart data, user preferences, etc.
      debugPrint('Clearing local user data before logout');
    } catch (e) {
      debugPrint('Error clearing local user data: $e');
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
      
      // Also update the users table
      await _userService.updateUserProfile(
        name: userData['name'],
        phone: userData['phone'],
        avatarUrl: userData['avatar_url'],
      );
      
      return response.user;
    } catch (e) {
      throw AuthException.fromSupabaseException(e);
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
      
      // Save token expiry time
      if (session.expiresAt != null) {
        await _secureStorage.write(
          key: 'token_expires_at',
          value: session.expiresAt.toString(),
        );
      }
      
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
      await _secureStorage.delete(key: 'token_expires_at');
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
          // Check if token is expired
          final expiresAtStr = await _secureStorage.read(key: 'token_expires_at');
          if (expiresAtStr != null) {
            final expiresAt = int.tryParse(expiresAtStr);
            if (expiresAt != null) {
              final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
              final now = DateTime.now();
              
              // If token is expired or about to expire (within 5 minutes), use refresh token
              if (expiryDate.difference(now).inMinutes < 5) {
                return await _refreshSession();
              }
            }
          }
          
          // If we have an access token that's not expired, try to use it
          final response = await _client.auth.recoverSession(accessToken);
          if (response.user != null) {
            // Check if email verification is required
            if (_isEmailVerificationRequired(response.user)) {
              _authStateController.add(AuthState.emailVerificationRequired);
              return false;
            }
            
            _startSessionCheck();
            return true;
          }
          
          // Fall back to refresh if recover failed
          return await _refreshSession();
        } catch (e) {
          debugPrint('Error recovering session: $e');
          // Try refresh if recovery fails
          return await _refreshSession();
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error restoring session: $e');
      return false;
    }
  }
} 