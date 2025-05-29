import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/error/exceptions.dart';
import '../utils/supabase_config_checker.dart';

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
      // Import dotenv to access environment variables
      final webClientId = dotenv.env['GOOGLE_CLIENT_ID'];
      final androidClientId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];

      debugPrint('🔍 [GoogleSignInService] Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      debugPrint('🔍 [GoogleSignInService] Web Client ID: ${webClientId != null ? 'Found' : 'Not found'}');
      debugPrint('🔍 [GoogleSignInService] Android Client ID: ${androidClientId != null ? 'Found' : 'Not found'}');

      // Configure GoogleSignIn based on platform
      late final GoogleSignIn googleSignIn;

      if (kIsWeb) {
        // For web, we need to provide the web client ID
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile', 'openid'],
          clientId: webClientId,
        );
        debugPrint('🔍 [GoogleSignInService] Configured for Web with client ID');
      } else {
        // For Android, we can use the google-services.json file
        // But we can also provide the client ID explicitly for extra safety
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile', 'openid'],
          // On Android, the client ID from google-services.json is used by default
          // But we can provide it explicitly for extra safety
          clientId: androidClientId,
        );
        debugPrint('🔍 [GoogleSignInService] Configured for Android with client ID from google-services.json');
      }

      debugPrint('🔍 [GoogleSignInService] GoogleSignIn instance created');
      final supabaseClient = Supabase.instance.client;
      debugPrint('🔍 [GoogleSignInService] SupabaseClient instance retrieved');

      _instance = GoogleSignInService(
        googleSignIn: googleSignIn,
        supabaseClient: supabaseClient,
      );
    }
    return _instance!;
  }

  /// Sign in with Google
  Future<AuthResponse> signIn() async {
    try {
      debugPrint('🔍 [GoogleSignInService] Starting Google Sign-In process');
      debugPrint('🔍 [GoogleSignInService] GoogleSignIn instance: $_googleSignIn');
      debugPrint('🔍 [GoogleSignInService] SupabaseClient instance: $_supabaseClient');

      // Check Supabase configuration
      final configResult = await SupabaseConfigChecker.checkSupabaseConfig();
      debugPrint('🔍 [GoogleSignInService] Supabase config: $configResult');

      if (configResult['error'] != null) {
        debugPrint('❌ [GoogleSignInService] Supabase config error: ${configResult['error']}');
      }

      // Check if Google provider is configured
      if (configResult['googleProviderConfigured'] == false) {
        debugPrint('❌ [GoogleSignInService] Google provider is not configured in Supabase');
        throw ServerException(
          message: 'Google sign-in is not properly configured in Supabase. Please contact support.',
        );
      }

      // First, ensure we're signed out from any previous sessions
      try {
        await _googleSignIn.signOut();
        debugPrint('🔍 [GoogleSignInService] Signed out from previous Google session');
      } catch (e) {
        debugPrint('🔍 [GoogleSignInService] No previous Google session to sign out from');
      }

      // Sign in with Google
      debugPrint('🔍 [GoogleSignInService] Calling _googleSignIn.signIn()');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ [GoogleSignInService] User cancelled Google sign-in');
        throw ServerException(message: 'Google sign-in was cancelled');
      }

      debugPrint('✅ [GoogleSignInService] Google Sign-In successful: ${googleUser.email}');
      debugPrint('🔍 [GoogleSignInService] Google User ID: ${googleUser.id}');
      debugPrint('🔍 [GoogleSignInService] Google User Display Name: ${googleUser.displayName}');

      // Get authentication data
      debugPrint('🔍 [GoogleSignInService] Getting authentication data');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      debugPrint('🔍 [GoogleSignInService] ID Token length: ${idToken?.length ?? 0}');
      debugPrint('🔍 [GoogleSignInService] Access Token length: ${accessToken?.length ?? 0}');

      if (idToken == null) {
        debugPrint('❌ [GoogleSignInService] Failed to get ID token from Google');
        throw ServerException(message: 'Failed to get ID token from Google');
      }

      debugPrint('🔍 [GoogleSignInService] Got Google ID token, signing in with Supabase');
      debugPrint('🔍 [GoogleSignInService] Supabase client: $_supabaseClient');

      // Sign in with Supabase using Google token
      debugPrint('🔍 [GoogleSignInService] Calling signInWithIdToken');
      try {
        // Print detailed information about the tokens
        debugPrint('🔍 [GoogleSignInService] ID Token first 20 chars: ${idToken.substring(0, 20)}...');
        if (accessToken != null) {
          debugPrint('🔍 [GoogleSignInService] Access Token first 20 chars: ${accessToken.substring(0, 20)}...');
        }

        // Try direct OAuth sign-in with Supabase
        try {
          debugPrint('🔍 [GoogleSignInService] Trying direct OAuth sign-in with Supabase');
          final oauthResponse = await _supabaseClient.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: 'com.dayliz.dayliz_app://login',
            queryParams: {
              'access_type': 'offline',
              'prompt': 'consent',
            },
          );

          debugPrint('🔍 [GoogleSignInService] OAuth response: $oauthResponse');

          if (oauthResponse) {
            debugPrint('✅ [GoogleSignInService] OAuth sign-in initiated successfully');
            // This is just the initial redirect - we need to wait for the callback
            // The actual session will be handled by the auth state change listener

            // Wait for the session to be established
            int attempts = 0;
            while (attempts < 10) {
              await Future.delayed(const Duration(seconds: 2));
              final session = _supabaseClient.auth.currentSession;
              if (session != null) {
                debugPrint('✅ [GoogleSignInService] Session established after OAuth flow');
                return AuthResponse(session: session, user: _supabaseClient.auth.currentUser);
              }
              attempts++;
              debugPrint('🔍 [GoogleSignInService] Waiting for session... Attempt $attempts');
            }
          }
        } catch (oauthError) {
          debugPrint('❌ [GoogleSignInService] OAuth sign-in error: $oauthError');
        }

        // Fall back to ID token sign-in
        debugPrint('🔍 [GoogleSignInService] Falling back to ID token sign-in');
        final response = await _supabaseClient.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        debugPrint('✅ [GoogleSignInService] Supabase sign-in successful: ${response.user?.email}');
        debugPrint('🔍 [GoogleSignInService] User ID: ${response.user?.id}');

        return response;
      } catch (supabaseError) {
        debugPrint('❌ [GoogleSignInService] Supabase signInWithIdToken error: $supabaseError');
        if (supabaseError.toString().contains('not configured')) {
          debugPrint('❌ [GoogleSignInService] Google provider not configured in Supabase');
          throw ServerException(
            message: 'Google sign-in is not properly configured. Please contact support.',
          );
        }

        // Try an alternative approach for Android
        if (!kIsWeb) {
          try {
            debugPrint('🔍 [GoogleSignInService] Trying alternative approach for Android');

            // Try to get a fresh token
            final googleUser = await _googleSignIn.signInSilently();
            if (googleUser != null) {
              final freshAuth = await googleUser.authentication;
              final freshIdToken = freshAuth.idToken;
              final freshAccessToken = freshAuth.accessToken;

              if (freshIdToken != null) {
                debugPrint('🔍 [GoogleSignInService] Got fresh tokens, trying again');
                final response = await _supabaseClient.auth.signInWithIdToken(
                  provider: OAuthProvider.google,
                  idToken: freshIdToken,
                  accessToken: freshAccessToken,
                );

                debugPrint('✅ [GoogleSignInService] Alternative sign-in successful');
                return response;
              }
            }
            debugPrint('❌ [GoogleSignInService] Could not get fresh tokens');
          } catch (alternativeError) {
            debugPrint('❌ [GoogleSignInService] Alternative approach failed: $alternativeError');
          }
        }

        // If all approaches fail, throw a descriptive error
        debugPrint('❌ [GoogleSignInService] All sign-in approaches failed');

        // Check for specific error messages
        final errorMsg = supabaseError.toString().toLowerCase();
        if (errorMsg.contains('not configured') || errorMsg.contains('provider not enabled')) {
          throw ServerException(
            message: 'Google sign-in is not properly configured in Supabase. Please contact support.',
          );
        } else if (errorMsg.contains('network') || errorMsg.contains('connection')) {
          throw ServerException(
            message: 'Network error. Please check your internet connection and try again.',
          );
        } else if (errorMsg.contains('timeout')) {
          throw ServerException(
            message: 'Connection timed out. Please try again later.',
          );
        } else if (errorMsg.contains('invalid token') || errorMsg.contains('token expired')) {
          throw ServerException(
            message: 'Authentication token error. Please try again.',
          );
        } else {
          throw ServerException(
            message: 'Server error occurred. Please try again later.\n\nDetails: ${supabaseError.toString()}',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [GoogleSignInService] Error during Google sign-in: $e');
      debugPrint('❌ [GoogleSignInService] Stack trace: $stackTrace');

      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to sign in with Google: ${e.toString()}');
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }
}
