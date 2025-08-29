import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../errors/exceptions.dart';
import 'production_logger.dart';

/// Service for handling Google Sign-In authentication
/// This is a specialized service that integrates with clean architecture
class GoogleSignInService {
  final GoogleSignIn _googleSignIn;
  final SupabaseClient _supabaseClient;

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
      debugPrint('🔄 [GoogleSignInService] Creating new instance...');

      // Import dotenv to access environment variables
      final webClientId = dotenv.env['GOOGLE_CLIENT_ID'];
      final androidClientId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];

      debugPrint('🔍 [GoogleSignInService] Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      debugPrint('🔍 [GoogleSignInService] Web Client ID: ${webClientId != null ? 'Found' : 'Not found'}');
      debugPrint('🔍 [GoogleSignInService] Android Client ID: ${androidClientId != null ? 'Found' : 'Not found'}');

      if (webClientId != null) {
        debugPrint('🔍 [GoogleSignInService] Web Client ID: ${webClientId.substring(0, 20)}...');
      }
      if (androidClientId != null) {
        debugPrint('🔍 [GoogleSignInService] Android Client ID: ${androidClientId.substring(0, 20)}...');
      }

      // Configure GoogleSignIn based on platform
      late final GoogleSignIn googleSignIn;

      if (kIsWeb) {
        // For web, we need to provide the web client ID
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile', 'openid'],
          clientId: webClientId,
        );
        ProductionLogger.auth('Configured for Web with client ID');
      } else {
        // For Android, try using the web client ID to fix ApiException: 10
        // Sometimes this resolves token exchange issues
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile', 'openid'],
          clientId: webClientId, // Use web client ID for Android too
        );
        debugPrint('🔍 [GoogleSignInService] Configured for Android using WEB client ID: ${webClientId != null ? 'Present' : 'Missing'}');
        debugPrint('🔍 [GoogleSignInService] Android Client ID from env: ${androidClientId != null ? 'Available but not used' : 'Not found'}');
      }

      _instance = GoogleSignInService(
        googleSignIn: googleSignIn,
        supabaseClient: Supabase.instance.client,
      );
    }
    return _instance!;
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

      // Sign in with Google (this will now show account picker)
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ [GoogleSignInService] User cancelled Google Sign-In');
        return null;
      }

      debugPrint('✅ [GoogleSignInService] Google Sign-In successful, user: ${googleUser.email}');

      // Get authentication data
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('❌ [GoogleSignInService] Failed to get ID token from Google');
        throw ServerException(message: 'Failed to get Google ID token');
      }

      debugPrint('✅ [GoogleSignInService] Got Google tokens, signing in to Supabase');

      // Sign in to Supabase with the Google tokens
      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        debugPrint('❌ [GoogleSignInService] No user returned from Supabase');
        throw ServerException(message: 'No user returned from Supabase');
      }

      debugPrint('✅ [GoogleSignInService] Supabase sign-in successful, user ID: ${response.user!.id}');
      return response;

    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error during Google Sign-in: $e');

      // Try to sign out from Google to clean up state
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        debugPrint('⚠️ [GoogleSignInService] Error signing out from Google: $signOutError');
      }

      if (e is ServerException) {
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

      // Sign in with Google (this will now show account picker)
      debugPrint('🔍 [GoogleSignInService] Calling _googleSignIn.signIn()');
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ [GoogleSignInService] User cancelled Google Sign-In or sign-in returned null');
        return null;
      }

      debugPrint('✅ [GoogleSignInService] Google user obtained: ${googleUser.email}');
      debugPrint('🔍 [GoogleSignInService] User ID: ${googleUser.id}');
      debugPrint('🔍 [GoogleSignInService] Display Name: ${googleUser.displayName}');

      // Get authentication data
      debugPrint('🔍 [GoogleSignInService] Getting authentication data...');
      final googleAuth = await googleUser.authentication;

      debugPrint('🔍 [GoogleSignInService] Authentication object obtained');
      debugPrint('🔍 [GoogleSignInService] Access Token: ${googleAuth.accessToken != null ? 'Present' : 'NULL'}');
      debugPrint('🔍 [GoogleSignInService] ID Token: ${googleAuth.idToken != null ? 'Present' : 'NULL'}');

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('❌ [GoogleSignInService] ID token is null!');
        debugPrint('🔍 [GoogleSignInService] Access token: ${accessToken != null ? 'Present' : 'Also null'}');
        return null;
      }

      debugPrint('✅ [GoogleSignInService] ID token obtained successfully');
      debugPrint('🔍 [GoogleSignInService] ID token length: ${idToken.length}');
      return idToken;
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error getting Google Auth Token: $e');
      debugPrint('🔍 [GoogleSignInService] Error type: ${e.runtimeType}');
      debugPrint('🔍 [GoogleSignInService] Error details: ${e.toString()}');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('✅ [GoogleSignInService] Signed out from Google');
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error signing out from Google: $e');
    }
  }

  /// Complete logout - signs out from both Google and Supabase
  /// This ensures the next sign-in will show account picker
  Future<void> completeLogout() async {
    try {
      debugPrint('🔄 [GoogleSignInService] Starting complete logout');

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
        debugPrint('✅ [GoogleSignInService] Signed out from Google');
      } catch (e) {
        debugPrint('⚠️ [GoogleSignInService] Error signing out from Google: $e');
      }

      debugPrint('✅ [GoogleSignInService] Complete logout finished');
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error during complete logout: $e');
    }
  }

  /// Force account selection on next sign-in
  /// This method ensures the Google account picker will be shown
  Future<void> forceAccountSelection() async {
    try {
      debugPrint('🔄 [GoogleSignInService] Forcing account selection for next sign-in');
      await _googleSignIn.signOut();
      debugPrint('✅ [GoogleSignInService] Account selection will be forced on next sign-in');
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error forcing account selection: $e');
    }
  }

  /// Check if user is currently signed in to Google
  Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error checking Google sign-in status: $e');
      return false;
    }
  }

  /// Get current Google user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Disconnect from Google (revokes access completely)
  /// This is more aggressive than signOut and revokes all permissions
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint('✅ [GoogleSignInService] Disconnected from Google (permissions revoked)');
    } catch (e) {
      debugPrint('❌ [GoogleSignInService] Error disconnecting from Google: $e');
    }
  }
}
