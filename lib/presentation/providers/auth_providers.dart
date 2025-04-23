import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart' hide NoParams;
import '../../domain/entities/user.dart' as domain;
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/is_authenticated_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';

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
  final GetCurrentUserUseCase getCurrentUserUseCase = sl<GetCurrentUserUseCase>();
  final IsAuthenticatedUseCase isAuthenticatedUseCase = sl<IsAuthenticatedUseCase>();
  final SignInWithGoogleUseCase signInWithGoogleUseCase = sl<SignInWithGoogleUseCase>();

  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password, {bool rememberMe = true}) async {
    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Call login use case
      final result = await loginUseCase(LoginParams(email: email, password: password, rememberMe: rememberMe));

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
    debugPrint('AuthNotifier: Starting registration for $email');
    debugPrint('AuthNotifier: Current state: isLoading=${state.isLoading}, isAuthenticated=${state.isAuthenticated}');

    try {
      debugPrint('AuthNotifier: Calling registerUseCase with email: $email, name: $name, phone: $phone');
      debugPrint('AuthNotifier: registerUseCase instance: $registerUseCase');

      // Call register use case
      final params = RegisterParams(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      debugPrint('AuthNotifier: Created RegisterParams');

      final result = await registerUseCase(params);
      debugPrint('AuthNotifier: registerUseCase call completed');

      debugPrint('AuthNotifier: Got result from registerUseCase');
      // Handle result
      result.fold(
        (failure) {
          debugPrint('AuthNotifier: Registration failed with error: ${failure.message}');

          // Check if we're already authenticated despite the error
          // This can happen if auth succeeded but profile creation failed
          if (state.isAuthenticated || state.user != null) {
            debugPrint('AuthNotifier: Already authenticated, ignoring error');
            state = state.copyWith(
              isLoading: false,
              clearError: true,
            );
            return;
          }

          // Check if we have a current user in Supabase despite the error
          // This is a workaround for the "Database error saving new user" issue
          getCurrentUser().then((userResult) {
            userResult.fold(
              (failure) {
                debugPrint('AuthNotifier: Failed to get current user after registration error');
                // No user found, show the original error
                state = state.copyWith(
                  errorMessage: _mapFailureToMessage(failure),
                  isLoading: false,
                );
              },
              (user) {
                if (user != null) {
                  debugPrint('AuthNotifier: Found user despite registration error: ${user.id}');
                  // User exists, update state to authenticated
                  state = state.copyWith(
                    isAuthenticated: true,
                    user: user,
                    isLoading: false,
                    clearError: true,
                  );
                } else {
                  debugPrint('AuthNotifier: No user found after registration error');
                  // No user found, show the original error
                  state = state.copyWith(
                    errorMessage: _mapFailureToMessage(failure),
                    isLoading: false,
                  );
                }
              },
            );
          });
        },
        (user) {
          debugPrint('AuthNotifier: Registration successful for user: ${user.id}');
          state = state.copyWith(
            isAuthenticated: true,
            user: user,
            isLoading: false,
            clearError: true,
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('AuthNotifier: Exception during registration: ${e.toString()}');
      debugPrint('AuthNotifier: Stack trace: $stackTrace');

      // Check if we're already authenticated despite the error
      if (state.isAuthenticated || state.user != null) {
        debugPrint('AuthNotifier: Already authenticated, ignoring error');
        state = state.copyWith(
          isLoading: false,
          clearError: true,
        );
        return;
      }

      // Check if we have a current user in Supabase despite the error
      getCurrentUser().then((userResult) {
        userResult.fold(
          (failure) {
            debugPrint('AuthNotifier: Failed to get current user after exception');
            // No user found, show a generic error
            state = state.copyWith(
              errorMessage: 'Server error occurred. Please try again later.',
              isLoading: false,
            );
          },
          (user) {
            if (user != null) {
              debugPrint('AuthNotifier: Found user despite exception: ${user.id}');
              // User exists, update state to authenticated
              state = state.copyWith(
                isAuthenticated: true,
                user: user,
                isLoading: false,
                clearError: true,
              );
            } else {
              debugPrint('AuthNotifier: No user found after exception');
              // No user found, show a generic error
              state = state.copyWith(
                errorMessage: 'Server error occurred. Please try again later.',
                isLoading: false,
              );
            }
          },
        );
      });
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

  /// Get the current user
  Future<Either<Failure, domain.User?>> getCurrentUser() async {
    try {
      debugPrint('AuthNotifier: Getting current user');
      return await getCurrentUserUseCase();
    } catch (e) {
      debugPrint('AuthNotifier: Error getting current user: ${e.toString()}');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Call the signInWithGoogle use case using the NoParams from sign_in_with_google_usecase.dart
      final result = await signInWithGoogleUseCase(const NoParams());

      // Handle result
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        ),
        (user) => state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          clearError: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
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