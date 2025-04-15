import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:dayliz_app/services/auth_service.dart' as auth_service show AuthState;
import 'package:dayliz_app/services/auth_service.dart' show AuthException, AuthErrorType;
import 'package:dayliz_app/services/auth_service.dart' show AuthService;

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

/// Provider for current auth error
final authErrorProvider = StateProvider<AuthException?>((ref) => null);

/// Auth notifier to handle authentication operations
class AuthNotifier extends StateNotifier<AuthState> {
  final StateNotifierProviderRef ref;
  
  AuthNotifier(this.ref) : super(AuthState.loading) {
    // Initialize auth service if not already initialized
    try {
      _initialize();
    } catch (e) {
      state = AuthState.unauthenticated;
      _setError(e);
    }
    
    // Listen to auth state changes from service
    AuthService.instance.authStateStream.listen((newState) {
      if (newState == AuthState.sessionExpired) {
        // Handle session expiry by attempting refresh
        _handleSessionExpiry();
      } else if (state != newState) {
        // Update state if it has changed
        state = newState;
        
        // Clear error when state changes successfully
        if (newState == AuthState.authenticated || 
            newState == AuthState.unauthenticated) {
          ref.read(authErrorProvider.notifier).state = null;
        }
      }
    });
  }

  /// Set error in the provider
  void _setError(dynamic error) {
    if (error is AuthException) {
      ref.read(authErrorProvider.notifier).state = error;
    } else {
      ref.read(authErrorProvider.notifier).state = AuthException(
        message: error.toString(),
        type: AuthErrorType.unknown,
        originalError: error,
      );
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
      _setError(e);
    }
  }
  
  /// Handle session expiry by attempting to refresh
  Future<void> _handleSessionExpiry() async {
    // We don't set state to loading to avoid UI flicker
    // The auth service will try to refresh and update the state accordingly
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading;
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      final response = await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      
      state = AuthState.authenticated;
      return response.user;
    } catch (e) {
      state = AuthState.unauthenticated;
      _setError(e);
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = AuthState.loading;
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      await AuthService.instance.signInWithGoogle();
      // The auth state will be updated via the auth state change listener
      // when the user completes the OAuth flow
    } catch (e) {
      state = AuthState.unauthenticated;
      _setError(e);
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
    bool requireEmailVerification = true,
  }) async {
    state = AuthState.loading;
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      final response = await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        userData: userData,
        requireEmailVerification: requireEmailVerification,
      );
      
      if (requireEmailVerification) {
        state = AuthState.emailVerificationRequired;
      } else {
        state = AuthState.authenticated;
      }
      
      return response.user;
    } catch (e) {
      state = AuthState.unauthenticated;
      _setError(e);
      rethrow;
    }
  }
  
  /// Send email verification
  Future<void> sendEmailVerification({
    required String email,
  }) async {
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      await AuthService.instance.sendEmailVerification(
        email: email,
      );
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }
  
  /// Verify email with token
  Future<bool> verifyEmail({
    required String token,
  }) async {
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      final success = await AuthService.instance.verifyEmail(
        token: token,
      );
      
      if (success) {
        state = AuthState.authenticated;
      }
      
      return success;
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword({
    required String email,
  }) async {
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      await AuthService.instance.resetPassword(
        email: email,
      );
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  /// Update password with access token from reset link
  Future<void> updatePassword({
    required String password,
    String? accessToken,
  }) async {
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      await AuthService.instance.updatePassword(
        password: password,
        accessToken: accessToken,
      );
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = AuthState.loading;
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      await AuthService.instance.signOut();
      state = AuthState.unauthenticated;
    } catch (e) {
      // If sign out fails, check if we're still authenticated
      state = AuthService.instance.isSignedIn 
        ? AuthState.authenticated 
        : AuthState.unauthenticated;
      _setError(e);
      rethrow;
    }
  }

  /// Update user profile
  Future<User?> updateProfile(Map<String, dynamic> userData) async {
    ref.read(authErrorProvider.notifier).state = null;
    
    try {
      return await AuthService.instance.updateProfile(userData);
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }
}

/// Provider for auth notifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
}); 