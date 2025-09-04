import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../errors/exceptions.dart';
import 'production_logger.dart';

/// Service for handling Google Sign-In authentication with v7.x API
/// This is a specialized service that integrates with clean architecture
class GoogleSignInService {
  final GoogleSignIn _googleSignIn;
  final SupabaseClient _supabaseClient;

  // Manual state management for v7.x (no more currentUser property)
  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;

  GoogleSignInService({
    required GoogleSignIn googleSignIn,
    required SupabaseClient supabaseClient,
  })  : _googleSignIn = googleSignIn,
        _supabaseClient = supabaseClient;

  /// Singleton instance
  static GoogleSignInService? _instance;

  /// Get the singleton instance
  static GoogleSignInService get instance {
    if (_instance == null) {
      debugPrint('🔄 [GoogleSignInService] Creating new instance with v7.x API...');

      // Import dotenv to access environment variables
      final webClientId = dotenv.env['GOOGLE_CLIENT_ID'];
      final androidClientId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];

      debugPrint('🔍 [GoogleSignInService] Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      debugPrint('🔍 [GoogleSignInService] Web Client ID: ${webClientId != null ? 'Found' : 'Not found'}');
      debugPrint('🔍 [GoogleSignInService] Android Client ID: ${androidClientId != null ? 'Found' : 'Not found'}');

      if (webClientId != null) {
        debugPrint('🔍 [GoogleSignInService] Web Client ID: ${webClientId.substring(0, 20)}...');
      }
      if (androidClientId != null && androidClientId != 'REPLACE_WITH_NEW_GOOGLE_ANDROID_CLIENT_ID') {
        debugPrint('🔍 [GoogleSignInService] Android Client ID: ${androidClientId.substring(0, 20)}...');
      }

      // Configure GoogleSignIn for v7.x API with serverClientId
      final googleSignIn = GoogleSignIn.instance;

      debugPrint('🔍 [GoogleSignInService] Using GoogleSignIn.instance (v7.x)');
      debugPrint('🔍 [GoogleSignInService] Will configure serverClientId during initialization');

      _instance = GoogleSignInService(
        googleSignIn: googleSignIn,
        supabaseClient: Supabase.instance.client,
      );
    }
    return _instance!;
  }

  /// Get current user (manual state management for v7.x)
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Ensure GoogleSignIn is initialized (required for v7.x)
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        debugPrint('🔄 [GoogleSignInService] Initializing GoogleSignIn v7.x...');

        // Get the Web Client ID for serverClientId (required for v7.x on Android)
        final webClientId = dotenv.env['GOOGLE_CLIENT_ID'];

        if (webClientId == null) {
          debugPrint('❌ [GoogleSignInService] GOOGLE_CLIENT_ID not found in environment');
          throw ServerException(message: 'Google Client ID not configured');
        }

        debugPrint('🔍 [GoogleSignInService] Using serverClientId: ${webClientId.substring(0, 20)}...');

        // Initialize with serverClientId for v7.x
        await _googleSignIn.initialize(
          serverClientId: webClientId,
        );

        _isInitialized = true;
        debugPrint('✅ [GoogleSignInService] GoogleSignIn initialized successfully with serverClientId');
      } catch (e) {
        debugPrint('❌ [GoogleSignInService] Failed to initialize GoogleSignIn: $e');
        throw ServerException(message: 'Failed to initialize Google Sign-In: ${e.toString()}');
      }
    }
  }

  /// Sign in with Google and return Supabase AuthResponse
  Future<AuthResponse?> signInWithGoogle({bool forceAccountSelection = true}) async {
    try {
      debugPrint('🔄 [GoogleSignInService] Starting Google Sign-in process');

      // Supabase configuration check removed for production

      // First, ensure we're signed out from any previous sessions
      try {
        await _supabaseClient.auth.signOut();
        debugPrint('🔍 [GoogleSignInService] Signed out from previous Supabase session');
      } catch (e) {
        debugPrint('🔍 [GoogleSignInService] No previous Supabase session to sign out from');
      }

      // CRITICAL FIX: Force account selection by signing out from Google first
      if (forceAccountSelection) {
        try {
          await _googleSignIn.signOut();
          debugPrint('🔍 [GoogleSignInService] Signed out from Google to force account selection');
        } catch (e) {
          debugPrint('🔍 [GoogleSignInService] No previous Google session to sign out from');
        }
      }

      // Ensure GoogleSignIn is initialized (required for v7.x)
      await _ensureInitialized();

      // Check if platform supports authenticate method
      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint('❌ [GoogleSignInService] Platform does not support authenticate() method');
        throw ServerException(message: 'Google Sign-In not supported on this platform');
      }

      // Authenticate with Google using v7.x API
      debugPrint('🔄 [GoogleSignInService] Authenticating with Google...');
      final googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'], // Specify required scopes
      );

      // Update manual state management (v7.x doesn't track currentUser automatically)
      _currentUser = googleUser;
      debugPrint('✅ [GoogleSignInService] Google authentication successful');
      debugPrint('🔍 [GoogleSignInService] User: ${googleUser.email}');

      // Get authentication tokens (synchronous in v7.x - no more await)
      final googleAuth = googleUser.authentication;
      debugPrint('🔍 [GoogleSignInService] Got authentication tokens');

      if (googleAuth.idToken == null) {
        debugPrint('❌ [GoogleSignInService] Missing ID token');
        throw ServerException(message: 'Failed to get Google ID token');
      }

      // Get authorization for required scopes (v7.x authorization flow)
      debugPrint('🔄 [GoogleSignInService] Getting authorization for scopes...');
      final authClient = _googleSignIn.authorizationClient;
      final requiredScopes = ['email', 'profile'];

      // Try to get existing authorization first
      var authorization = await authClient.authorizationForScopes(requiredScopes);

      if (authorization == null) {
        debugPrint('🔄 [GoogleSignInService] Requesting new authorization...');
        // Request new authorization from user
        authorization = await authClient.authorizeScopes(requiredScopes);
      }

      if (authorization?.accessToken == null) {
        debugPrint('❌ [GoogleSignInService] Failed to get access token');
        throw ServerException(message: 'Failed to get Google access token');
      }

      debugPrint('✅ [GoogleSignInService] Got access token for scopes');

      // Sign in to Supabase with Google tokens
      debugPrint('🔄 [GoogleSignInService] Signing in to Supabase with Google tokens');
      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: authorization!.accessToken!,
      );

      debugPrint('✅ [GoogleSignInService] Supabase authentication successful');
      return response;

    } on GoogleSignInException catch (e) {
      debugPrint('❌ [GoogleSignInService] Google Sign-In Exception: ${e.code.name}');
      debugPrint('🔍 [GoogleSignInService] Description: ${e.description}');
      debugPrint('🔍 [GoogleSignInService] Details: ${e.details}');

      // Clear state on error
      _currentUser = null;

      // Handle specific Google Sign-In errors
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          debugPrint('🔍 [GoogleSignInService] User cancelled Google Sign-In');
          throw UserCancellationException(message: 'Google Sign-In cancelled by user');
        case GoogleSignInExceptionCode.interrupted:
          throw ServerException(message: 'Google Sign-In was interrupted. Please try again.');
        case GoogleSignInExceptionCode.clientConfigurationError:
          throw ServerException(message: 'Google Sign-In configuration error. Please contact support.');
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw ServerException(message: 'Google Sign-In provider not configured. Please contact support.');
        case GoogleSignInExceptionCode.uiUnavailable:
          throw ServerException(message: 'Google Sign-In UI unavailable. Please try again later.');
        case GoogleSignInExceptionCode.userMismatch:
          throw ServerException(message: 'Account mismatch. Please sign out and try again.');
        case GoogleSignInExceptionCode.unknownError:
          throw ServerException(message: 'Google Sign-In failed: ${e.description ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error during Google Sign-in: $e');

      // Clear state and try to sign out from Google to clean up
      _currentUser = null;
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        debugPrint('⚠️ [GoogleSignInService] Error signing out from Google: $signOutError');
      }

      if (e is ServerException || e is UserCancellationException) {
        rethrow;
      }
      throw ServerException(message: 'Google sign-in failed: ${e.toString()}');
    }
  }

  /// Get Google Auth Token for authentication
  /// Returns the ID token that can be used with Supabase
  Future<String?> getGoogleAuthToken({bool forceAccountSelection = true}) async {
    try {
      debugPrint('🔄 [GoogleSignInService] Starting getGoogleAuthToken');

      // CRITICAL FIX: Force account selection by signing out from Google first
      if (forceAccountSelection) {
        try {
          await _googleSignIn.signOut();
          debugPrint('🔍 [GoogleSignInService] Signed out from Google to force account selection');
        } catch (e) {
          debugPrint('🔍 [GoogleSignInService] No previous Google session to sign out from');
        }
      }

      // Ensure GoogleSignIn is initialized (required for v7.x)
      await _ensureInitialized();

      // Check if platform supports authenticate method
      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint('❌ [GoogleSignInService] Platform does not support authenticate() method');
        return null;
      }

      // Authenticate with Google using v7.x API
      final googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Update manual state management
      _currentUser = googleUser;

      // Get authentication tokens (synchronous in v7.x)
      final googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('❌ [GoogleSignInService] Missing ID token');
        return null;
      }

      debugPrint('✅ [GoogleSignInService] Successfully got Google Auth Token');
      return googleAuth.idToken;

    } on GoogleSignInException catch (e) {
      debugPrint('❌ [GoogleSignInService] Google Sign-In Exception: ${e.code.name}');
      _currentUser = null; // Clear state on error

      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('🔍 [GoogleSignInService] User cancelled Google Sign-In');
        return null; // Return null for cancellation, don't throw
      }

      debugPrint('🔍 [GoogleSignInService] Error: ${e.description}');
      return null;
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error getting Google Auth Token: $e');
      debugPrint('🔍 [GoogleSignInService] Error type: ${e.runtimeType}');
      debugPrint('🔍 [GoogleSignInService] Error details: ${e.toString()}');
      _currentUser = null; // Clear state on error
      return null;
    }
  }

  /// Sign out from Google using v7.x API
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null; // Clear manual state management
      debugPrint('✅ [GoogleSignInService] Signed out from Google');
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error signing out from Google: $e');
    }
  }

  /// Complete logout - signs out from both Google and Supabase using v7.x API
  /// This ensures the next sign-in will show account picker
  Future<void> completeLogout() async {
    try {
      debugPrint('🔄 [GoogleSignInService] Starting complete logout with v7.x API');

      // Sign out from Supabase first
      try {
        await _supabaseClient.auth.signOut();
        debugPrint('✅ [GoogleSignInService] Signed out from Supabase');
      } catch (e) {
        debugPrint('⚠️ [GoogleSignInService] Error signing out from Supabase: $e');
      }

      // Sign out from Google to clear cached account
      try {
        await _googleSignIn.signOut();
        _currentUser = null; // Clear manual state management
        debugPrint('✅ [GoogleSignInService] Signed out from Google');
      } catch (e) {
        debugPrint('⚠️ [GoogleSignInService] Error signing out from Google: $e');
      }

      debugPrint('✅ [GoogleSignInService] Complete logout finished');
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error during complete logout: $e');
    }
  }

  /// Force account selection on next sign-in using v7.x API
  /// This method ensures the Google account picker will be shown
  Future<void> forceAccountSelection() async {
    try {
      debugPrint('🔄 [GoogleSignInService] Forcing account selection for next sign-in');
      await _googleSignIn.signOut();
      _currentUser = null; // Clear manual state management
      debugPrint('✅ [GoogleSignInService] Account selection will be forced on next sign-in');
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error forcing account selection: $e');
    }
  }



  /// Disconnect from Google (revokes access completely) using v7.x API
  /// This is more aggressive than signOut and revokes all permissions
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      _currentUser = null; // Clear manual state management
      debugPrint('✅ [GoogleSignInService] Disconnected from Google (permissions revoked)');
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error disconnecting from Google: $e');
    }
  }
}
