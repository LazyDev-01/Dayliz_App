import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class to check Supabase configuration
class SupabaseConfigChecker {
  /// Check if the Google provider is properly configured in Supabase
  static Future<bool> isGoogleProviderConfigured() async {
    try {
      final client = Supabase.instance.client;

      // Try to get the list of enabled providers
      final response = await client.functions.invoke('check-google-provider');

      debugPrint('🔍 [SupabaseConfigChecker] Google provider check response: ${response.data}');

      if (response.data != null && response.data is Map) {
        final isEnabled = response.data['isGoogleEnabled'] as bool?;
        if (isEnabled != null) {
          return isEnabled;
        }
      }

      // If we can't get a clear answer, try the older function
      try {
        final oldResponse = await client.functions.invoke('check-auth-providers');

        debugPrint('🔍 [SupabaseConfigChecker] Auth providers response: ${oldResponse.data}');

        if (oldResponse.data != null && oldResponse.data is Map) {
          final providers = oldResponse.data['providers'] as List?;
          if (providers != null) {
            return providers.contains('google');
          }
        }
      } catch (innerError) {
        debugPrint('❌ [SupabaseConfigChecker] Error with fallback check: $innerError');
      }

      // If we can't get the list of providers, assume it's not configured
      return false;
    } catch (e) {
      debugPrint('❌ [SupabaseConfigChecker] Error checking Google provider: $e');
      // If there's an error, we'll assume the provider is not configured
      return false;
    }
  }

  /// Check if the Supabase project is properly configured
  static Future<Map<String, dynamic>> checkSupabaseConfig() async {
    final result = <String, dynamic>{
      'isInitialized': false,
      'hasClient': false,
      'currentUser': null,
      'googleProviderConfigured': false,
      'error': null,
    };

    try {
      // Check if Supabase is initialized
      try {
        final client = Supabase.instance.client;
        result['isInitialized'] = true;
        result['hasClient'] = true;
        result['currentUser'] = client.auth.currentUser?.email;
      } catch (e) {
        result['error'] = 'Supabase not initialized: $e';
        return result;
      }

      // Check if Google provider is configured
      try {
        result['googleProviderConfigured'] = await isGoogleProviderConfigured();
      } catch (e) {
        result['error'] = 'Error checking Google provider: $e';
      }

      return result;
    } catch (e) {
      result['error'] = 'Unexpected error: $e';
      return result;
    }
  }
}
