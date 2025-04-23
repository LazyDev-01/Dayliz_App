import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A simplified Google Sign-In service that directly uses the Supabase signInWithOAuth method
class DirectGoogleSignInService {
  static final DirectGoogleSignInService _instance = DirectGoogleSignInService._internal();
  static DirectGoogleSignInService get instance => _instance;

  late final SupabaseClient _supabaseClient;
  
  DirectGoogleSignInService._internal() {
    _supabaseClient = Supabase.instance.client;
  }

  /// Sign in with Google using the OAuth flow
  Future<AuthResponse?> signIn() async {
    try {
      debugPrint('🔍 [DirectGoogleSignInService] Starting Google Sign-In process');
      
      // First, sign out from any existing session
      try {
        await _supabaseClient.auth.signOut();
        debugPrint('🔍 [DirectGoogleSignInService] Signed out from previous session');
      } catch (e) {
        debugPrint('🔍 [DirectGoogleSignInService] No previous session to sign out from: $e');
      }
      
      // Use the OAuth flow directly
      final result = await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.dayliz.dayliz_app://login',
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
      
      debugPrint('🔍 [DirectGoogleSignInService] OAuth result: $result');
      
      if (result) {
        debugPrint('✅ [DirectGoogleSignInService] OAuth flow initiated successfully');
        
        // Wait for the session to be established
        int attempts = 0;
        while (attempts < 15) {  // Wait up to 30 seconds
          await Future.delayed(const Duration(seconds: 2));
          final session = _supabaseClient.auth.currentSession;
          final user = _supabaseClient.auth.currentUser;
          
          if (session != null && user != null) {
            debugPrint('✅ [DirectGoogleSignInService] Session established: ${user.email}');
            return AuthResponse(session: session, user: user);
          }
          
          attempts++;
          debugPrint('🔍 [DirectGoogleSignInService] Waiting for session... Attempt $attempts');
        }
        
        throw Exception('Timed out waiting for authentication session');
      } else {
        throw Exception('Failed to initiate Google Sign-In');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [DirectGoogleSignInService] Error: $e');
      debugPrint('❌ [DirectGoogleSignInService] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
