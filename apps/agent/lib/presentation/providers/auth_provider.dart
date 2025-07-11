import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_types/shared_types.dart';
import 'package:business_logic/business_logic.dart';
import '../../core/services/service_locator.dart';

/// Auth state for the application
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final AgentModel? agent;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.agent,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AgentModel? agent,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      agent: agent ?? this.agent,
      errorMessage: errorMessage,
    );
  }
}

/// Auth provider for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = sl<AuthService>();

  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check current authentication status
  void _checkAuthStatus() {
    final isLoggedIn = _authService.isLoggedIn;
    final currentAgent = _authService.currentAgent;

    if (isLoggedIn && currentAgent != null) {
      state = state.copyWith(
        isAuthenticated: true,
        agent: currentAgent,
      );
    }
  }

  /// Login with agent ID and password
  Future<void> login(String agentId, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _authService.login(
        agentId: agentId,
        password: password,
      );

      if (result.isSuccess && result.agent != null) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          agent: result.agent,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: result.errorMessage ?? 'Login failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Logout the current agent
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.logout();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Logout failed: ${e.toString()}',
      );
    }
  }

  /// Update agent status
  Future<void> updateAgentStatus(AgentStatus status) async {
    if (state.agent == null) return;

    final success = await _authService.updateAgentStatus(status);
    if (success) {
      state = state.copyWith(
        agent: state.agent!.copyWith(status: status),
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh agent profile
  Future<void> refreshProfile() async {
    final agent = await _authService.getAgentProfile();
    if (agent != null) {
      state = state.copyWith(agent: agent);
    }
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Convenience provider for getting current agent
final currentAgentProvider = Provider<AgentModel?>((ref) {
  return ref.watch(authProvider).agent;
});