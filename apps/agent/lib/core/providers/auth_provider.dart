import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_types/shared_types.dart';
import '../services/auth_service.dart';

/// Authentication state for the agent app
class AuthState {
  final AgentModel? agent;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.agent,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    AgentModel? agent,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      agent: agent ?? this.agent,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// AuthNotifier manages authentication state and operations
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initializeAuth();
  }

  /// Initialize authentication state on app start
  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);
    
    try {
      if (_authService.isAuthenticated) {
        final agent = await _authService.getCurrentAgent();
        if (agent != null) {
          state = state.copyWith(
            agent: agent,
            isAuthenticated: true,
            isLoading: false,
          );
        } else {
          // User exists but no agent data - logout
          await _authService.logout();
          state = state.copyWith(
            isAuthenticated: false,
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize authentication: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Login with Email/Phone and password
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final agent = await _authService.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      
      state = state.copyWith(
        agent: agent,
        isAuthenticated: true,
        isLoading: false,
      );
      
      return true;
      
    } on AuthException catch (e) {
      state = state.copyWith(
        error: e.message,
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Login failed: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Submit agent application
  Future<String?> submitApplication({
    required String fullName,
    required String phone,
    required String email,
    required String workType,
    required int age,
    required String gender,
    required String address,
    required String vehicleType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final message = await _authService.submitApplication(
        fullName: fullName,
        phone: phone,
        email: email,
        workType: workType,
        age: age,
        gender: gender,
        address: address,
        vehicleType: vehicleType,
      );
      
      state = state.copyWith(isLoading: false);
      return message;
      
    } on AuthException catch (e) {
      state = state.copyWith(
        error: e.message,
        isLoading: false,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        error: 'Registration failed: ${e.toString()}',
        isLoading: false,
      );
      return null;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _authService.logout();
      state = const AuthState(isAuthenticated: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Logout failed: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        error: e.message,
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Password reset failed: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.updatePassword(newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        error: e.message,
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Password update failed: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh current agent data
  Future<void> refreshAgent() async {
    if (!state.isAuthenticated) return;
    
    try {
      final agent = await _authService.getCurrentAgent();
      if (agent != null) {
        state = state.copyWith(agent: agent);
      }
    } catch (e) {
      // Silently fail for refresh operations
    }
  }
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience provider for current agent
final currentAgentProvider = Provider<AgentModel?>((ref) {
  return ref.watch(authProvider).agent;
});

/// Convenience provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Convenience provider for loading state
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Convenience provider for error state
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
