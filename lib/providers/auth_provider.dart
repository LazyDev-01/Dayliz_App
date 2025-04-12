import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/services/auth_service.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/services/auth_service.dart' as auth_service show AuthState;

// Use our own AuthState to avoid ambiguity
typedef AuthState = auth_service.AuthState;

/// Provider for auth state
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.authStateStream;
});

/// Provider for the current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (state) {
      if (state == AuthState.authenticated) {
        return AuthService.instance.currentUser;
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Auth notifier to handle authentication operations
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading) {
    // Initialize auth service if not already initialized
    try {
      _initialize();
    } catch (e) {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> _initialize() async {
    state = AuthState.loading;
    
    try {
      await AuthService.instance.initialize();
      final isSignedIn = await AuthService.instance.restoreSession();
      
      state = isSignedIn ? AuthState.authenticated : AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
    }
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading;
    
    try {
      final response = await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      
      state = AuthState.authenticated;
      return response.user;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    state = AuthState.loading;
    
    try {
      final response = await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        userData: userData,
      );
      
      state = AuthState.authenticated;
      return response.user;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  /// Sign in with phone and password
  Future<User?> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    state = AuthState.loading;
    
    try {
      final response = await AuthService.instance.signInWithPhone(
        phone: phone,
        password: password,
      );
      
      state = AuthState.authenticated;
      return response.user;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  /// Send OTP to phone
  Future<void> sendOtp({
    required String phone,
  }) async {
    try {
      await AuthService.instance.sendOtp(
        phone: phone,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP
  Future<User?> verifyOtp({
    required String phone,
    required String token,
  }) async {
    state = AuthState.loading;
    
    try {
      final response = await AuthService.instance.verifyOtp(
        phone: phone,
        token: token,
      );
      
      state = AuthState.authenticated;
      return response.user;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword({
    required String email,
  }) async {
    try {
      await AuthService.instance.resetPassword(
        email: email,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = AuthState.loading;
    
    try {
      await AuthService.instance.signOut();
      state = AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.authenticated;
      rethrow;
    }
  }

  /// Update user profile
  Future<User?> updateProfile(Map<String, dynamic> userData) async {
    try {
      return await AuthService.instance.updateProfile(userData);
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for auth notifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
}); 