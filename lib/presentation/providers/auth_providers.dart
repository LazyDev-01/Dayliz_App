import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/is_authenticated_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';

// Get the service locator instance
final sl = GetIt.instance;

/// Auth state class
class AuthState {
  final bool isAuthenticated;
  final domain.User? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    domain.User? user,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// User class
class User {
  final String id;
  final String email;
  final String? displayName;

  const User({
    required this.id,
    required this.email,
    this.displayName,
  });
}

/// Auth state provider
final authStateProvider = StateProvider<AuthState>((ref) {
  // Default to unauthenticated state
  return const AuthState();
});

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase = sl<LoginUseCase>();
  final RegisterUseCase registerUseCase = sl<RegisterUseCase>();
  final LogoutUseCase logoutUseCase = sl<LogoutUseCase>();
  final ForgotPasswordUseCase forgotPasswordUseCase = sl<ForgotPasswordUseCase>();

  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Call login use case
      final result = await loginUseCase(LoginParams(email: email, password: password));
      
      // Handle result
      result.fold(
        (failure) => state = state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        ),
        (user) => state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }
  
  Future<void> register(String email, String password, String name, {String? phone}) async {
    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Call register use case
      final result = await registerUseCase(RegisterParams(
        email: email,
        password: password,
        name: name,
      ));
      
      // Handle result
      result.fold(
        (failure) => state = state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        ),
        (user) => state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<Either<Failure, bool>> logout() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final result = await logoutUseCase();
      state = state.copyWith(isLoading: false);

      return result.fold(
        (failure) {
          state = state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isAuthenticated: true,
          );
          return Left(failure);
        },
        (success) {
          if (success) {
            state = state.copyWith(
              isAuthenticated: false,
              user: null,
            );
          }
          return Right(success);
        },
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }
  
  Future<bool> forgotPassword(String email) async {
    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Call forgot password use case
      final result = await forgotPasswordUseCase(ForgotPasswordParams(email: email));
      
      // Handle result
      return result.fold(
        (failure) {
          state = state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isLoading: false,
          );
          return false;
        },
        (_) {
          state = state.copyWith(isLoading: false, clearError: true);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }
}

/// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience providers for specific auth states

/// Loading state provider
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoading;
});

/// Error message provider
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).errorMessage;
});

/// Current user provider
final currentUserProvider = Provider<domain.User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// Authentication status provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

/// Map failure to user-friendly message
String _mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure:
      return 'Server error occurred. Please try again later.';
    case NetworkFailure:
      return 'Network error. Please check your internet connection.';
    case AuthFailure:
      return failure.message;
    default:
      return 'An unexpected error occurred.';
  }
} 