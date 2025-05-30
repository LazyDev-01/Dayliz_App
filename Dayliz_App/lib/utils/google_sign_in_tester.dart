import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Utility class to test Google Sign-In configuration
class GoogleSignInTester {
  /// Test the Google Sign-In configuration in Supabase
  static Future<Map<String, dynamic>> testGoogleSignInConfig() async {
    final result = <String, dynamic>{
      'supabaseUrl': null,
      'supabaseAnonKey': null,
      'googleClientId': null,
      'googleRedirectUri': null,
      'isSupabaseInitialized': false,
      'isGoogleProviderEnabled': false,
      'error': null,
    };

    try {
      // Check environment variables
      result['supabaseUrl'] = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      result['supabaseAnonKey'] = anonKey != null ? '${anonKey.substring(0, anonKey.length > 10 ? 10 : anonKey.length)}...' : 'Not found';
      result['googleClientId'] = dotenv.env['GOOGLE_CLIENT_ID'];
      result['googleRedirectUri'] = dotenv.env['GOOGLE_REDIRECT_URI'];

      // Check if Supabase is initialized
      try {
        final client = Supabase.instance.client;
        result['isSupabaseInitialized'] = true;

        // Check if Google provider is enabled
        try {
          // This is a direct test of the OAuth flow
          // We're not actually signing in, just checking if the provider is configured
          // Just check if the call succeeds without actually completing the flow
          await client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: 'com.dayliz.dayliz_app://login',
          );

          // If we get here without an error, the provider is configured
          result['isGoogleProviderEnabled'] = true;
        } catch (e) {
          debugPrint('❌ [GoogleSignInTester] Error testing Google provider: $e');

          // Check the error message to determine if the provider is configured
          final errorMsg = e.toString().toLowerCase();
          if (errorMsg.contains('not configured') ||
              errorMsg.contains('provider not enabled') ||
              errorMsg.contains('provider is not enabled')) {
            result['isGoogleProviderEnabled'] = false;
            result['error'] = 'Google provider is not enabled in Supabase';
          } else {
            // If the error is not about the provider being disabled,
            // it might be configured but there's another issue
            result['isGoogleProviderEnabled'] = true;
            result['error'] = 'Error testing Google provider: $e';
          }
        }
      } catch (e) {
        result['error'] = 'Supabase not initialized: $e';
      }

      return result;
    } catch (e) {
      result['error'] = 'Unexpected error: $e';
      return result;
    }
  }
}
