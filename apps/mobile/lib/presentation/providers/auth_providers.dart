import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';

import '../../domain/entities/user.dart' as domain;
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/is_authenticated_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart' as google_signin;
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/check_email_exists_usecase.dart';

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

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final IsAuthenticatedUseCase isAuthenticatedUseCase;
  final google_signin.SignInWithGoogleUseCase signInWithGoogleUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final CheckEmailExistsUseCase checkEmailExistsUseCase;

  AuthNotifier({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.forgotPasswordUseCase,
    required this.getCurrentUserUseCase,
    required this.isAuthenticatedUseCase,
    required this.signInWithGoogleUseCase,
    required this.resetPasswordUseCase,
    required this.changePasswordUseCase,
    required this.checkEmailExistsUseCase,
  }) : super(const AuthState());

  // Constructor that uses service locator
  factory AuthNotifier.fromServiceLocator() {
    return AuthNotifier(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      isAuthenticatedUseCase: sl<IsAuthenticatedUseCase>(),
      signInWithGoogleUseCase: sl<google_signin.SignInWithGoogleUseCase>(),
      resetPasswordUseCase: sl<ResetPasswordUseCase>(),
      changePasswordUseCase: sl<ChangePasswordUseCase>(),
      checkEmailExistsUseCase: sl<CheckEmailExistsUseCase>(),
    );
  }

  Future<void> login(String email, String password, {bool rememberMe = true}) async {
    debugPrint('🔄 [AuthNotifier] Starting login for email: $email');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await loginUseCase(LoginParams(email: email, password: password, rememberMe: rememberMe));

      result.fold(
        (failure) {
          debugPrint('🔍 [AuthNotifier] Login failed with failure: ${failure.runtimeType} - ${failure.message}');
          state = state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isLoading: false,
          );
        },
        (user) {
          debugPrint('✅ [AuthNotifier] Login successful for user: ${user.id}');
          state = state.copyWith(
            isAuthenticated: true,
            user: user,
            isLoading: false,
            clearError: true,
          );
        },
      );
    } catch (e) {
      debugPrint('🔍 [AuthNotifier] Login caught exception: ${e.toString()}');
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> register(String email, String password, String name, {String? phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final params = RegisterParams(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      final result = await registerUseCase(params);

      result.fold(
        (failure) {
          String errorMsg = failure.message.toLowerCase();
          if (errorMsg.contains('already registered') ||
              errorMsg.contains('email is already') ||
              errorMsg.contains('email already') ||
              errorMsg.contains('already exists') ||
              errorMsg.contains('duplicate') ||
              errorMsg.contains('already in use')) {

            try {
              Supabase.instance.client.auth.signOut();
            } catch (e) {
              debugPrint('AuthNotifier: Error signing out: $e');
            }

            state = state.copyWith(
              errorMessage: 'This email is already registered. Please use a different email or try logging in.',
              isLoading: false,
              isAuthenticated: false,
              user: null,
            );
          } else {
            state = state.copyWith(
              errorMessage: _mapFailureToMessage(failure),
              isLoading: false,
            );
          }
        },
        (user) {
          state = state.copyWith(
            isAuthenticated: true,
            user: user,
            isLoading: false,
            clearError: true,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Registration failed: ${e.toString()}',
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
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await forgotPasswordUseCase(ForgotPasswordParams(email: email));

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

  Future<bool> updatePassword({
    required String password,
    String? accessToken,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await resetPasswordUseCase(ResetPasswordParams(
        token: accessToken ?? '',
        newPassword: password,
      ));

      return result.fold(
        (failure) {
          state = state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isLoading: false,
          );
          return false;
        },
        (success) {
          state = state.copyWith(isLoading: false, clearError: true);
          return success;
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

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await changePasswordUseCase(ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ));

      return result.fold(
        (failure) {
          state = state.copyWith(
            errorMessage: _mapFailureToMessage(failure),
            isLoading: false,
          );
          return false;
        },
        (success) {
          state = state.copyWith(isLoading: false, clearError: true);
          return success;
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

  Future<Either<Failure, domain.User?>> getCurrentUser() async {
    try {
      return await getCurrentUserUseCase();
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await signInWithGoogleUseCase(const google_signin.NoParams());

      result.fold(
        (failure) {
          // CRITICAL FIX: Handle user cancellation silently
          if (failure is UserCancellationFailure) {
            debugPrint('🔍 [AuthNotifier] User cancelled Google Sign-In - handling silently');
            state = state.copyWith(
              isLoading: false,
              clearError: true, // Don't show any error message
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              errorMessage: _mapFailureToMessage(failure),
            );
          }
        },
        (user) => state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          clearError: true,
        ),
      );
    } catch (e) {
      // CRITICAL FIX: Handle user cancellation silently even in catch block
      if (e.toString().contains('UserCancellationException') ||
          e.toString().contains('cancelled by user')) {
        debugPrint('🔍 [AuthNotifier] User cancelled Google Sign-In in catch block - handling silently');
        state = state.copyWith(
          isLoading: false,
          clearError: true, // Don't show any error message
        );
        return; // Don't rethrow for cancellation
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<bool> verifyEmail({required String token}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(
        isLoading: false,
        clearError: true,
      );

      final userResult = await getCurrentUser();
      userResult.fold(
        (failure) {
          debugPrint('Error refreshing user after email verification: ${failure.message}');
        },
        (user) {
          if (user != null) {
            state = state.copyWith(
              user: user,
              isAuthenticated: true,
            );
          }
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error verifying email: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to verify email: ${e.toString()}',
      );
      return false;
    }
  }

  void clearErrors() {
    state = state.copyWith(clearError: true);
  }

  /// Send OTP to phone number for authentication
  Future<void> sendPhoneOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Import Supabase client
      final supabase = Supabase.instance.client;

      await supabase.auth.signInWithOtp(
        phone: phoneNumber,
        shouldCreateUser: true,
      );

      state = state.copyWith(
        isLoading: false,
        clearError: true,
      );

      debugPrint('✅ OTP sent successfully to $phoneNumber');
    } on AuthException catch (e) {
      debugPrint('❌ Phone OTP error: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapPhoneAuthError(e),
      );
    } catch (e) {
      debugPrint('❌ Unexpected phone OTP error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP. Please try again.',
      );
    }
  }

  /// Verify OTP and complete phone authentication
  Future<void> verifyPhoneOtp(String phoneNumber, String otpCode) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Import Supabase client
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: otpCode,
        type: OtpType.sms,
      );

      if (response.user != null) {
        // Create user profile if needed
        await _createUserProfileIfNeeded(response.user!);

        // Get user data from domain layer
        final userResult = await getCurrentUser();
        userResult.fold(
          (failure) {
            debugPrint('Error getting user after phone auth: ${failure.message}');
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'Authentication successful but failed to load user data.',
            );
          },
          (user) {
            if (user != null) {
              state = state.copyWith(
                isAuthenticated: true,
                user: user,
                isLoading: false,
                clearError: true,
              );
              debugPrint('✅ Phone authentication successful for user: ${user.id}');
            } else {
              state = state.copyWith(
                isLoading: false,
                errorMessage: 'Authentication successful but user data not found.',
              );
            }
          },
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Verification failed. Please try again.',
        );
      }
    } on AuthException catch (e) {
      debugPrint('❌ OTP verification error: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapOtpVerificationError(e),
      );
    } catch (e) {
      debugPrint('❌ Unexpected OTP verification error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Verification failed. Please try again.',
      );
    }
  }

  /// Create user profile in profiles table if needed
  Future<void> _createUserProfileIfNeeded(User user) async {
    try {
      final supabase = Supabase.instance.client;

      // Check if profile already exists
      final existingProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile
        await supabase.from('profiles').insert({
          'id': user.id,
          'phone': user.phone,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ User profile created for: ${user.id}');
      } else {
        debugPrint('ℹ️ User profile already exists for: ${user.id}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to create user profile: $e');
      // Don't throw error as auth was successful
    }
  }

  /// Map phone auth errors to user-friendly messages
  String _mapPhoneAuthError(AuthException error) {
    switch (error.message.toLowerCase()) {
      case 'invalid phone number':
        return 'Please enter a valid phone number';
      case 'phone rate limit exceeded':
        return 'Too many attempts. Please try again later';
      case 'sms not configured':
        return 'SMS service is currently unavailable';
      default:
        return 'Failed to send OTP. Please try again';
    }
  }

  /// Map OTP verification errors to user-friendly messages
  String _mapOtpVerificationError(AuthException error) {
    switch (error.message.toLowerCase()) {
      case 'invalid otp':
      case 'otp expired':
        return 'Invalid or expired code. Please try again.';
      case 'too many requests':
        return 'Too many attempts. Please wait before trying again.';
      default:
        return 'Verification failed. Please try again.';
    }
  }

  /// Check if an email already exists in the system
  Future<bool> checkEmailExists(String email) async {
    try {
      debugPrint('🔄 [AuthNotifier] Checking if email exists: $email');

      final result = await checkEmailExistsUseCase(CheckEmailExistsParams(email: email));

      return result.fold(
        (failure) {
          debugPrint('❌ [AuthNotifier] Email check failed: ${failure.message}');
          // On failure, return false to allow user to proceed (fail-safe approach)
          return false;
        },
        (exists) {
          debugPrint('✅ [AuthNotifier] Email exists check result: $exists');
          return exists;
        },
      );
    } catch (e) {
      debugPrint('❌ [AuthNotifier] Error checking email existence: $e');
      // On error, return false to allow user to proceed (fail-safe approach)
      return false;
    }
  }

  /// ENHANCED FIX: Set validation error without triggering auth operations
  void setValidationError(String message) {
    state = state.copyWith(
      errorMessage: message,
      isLoading: false,
    );
  }

  String _mapFailureToMessage(Failure failure) {
    debugPrint('🔍 [AuthNotifier] Mapping failure: ${failure.runtimeType} - ${failure.message}');

    if (failure is AuthFailure && failure.message == "No authenticated user found") {
      return "";
    }

    switch (failure.runtimeType) {
      case ServerFailure:
        debugPrint('🔍 [AuthNotifier] Returning actual server error message: ${failure.message}');
        // CRITICAL FIX: Return the actual server error message instead of generic message
        // This allows users to see specific errors like password requirements, email issues, etc.
        return failure.message.isNotEmpty
            ? failure.message
            : 'Server error occurred. Please try again later.';
      case NetworkFailure:
        debugPrint('🔍 [AuthNotifier] Returning network error message');
        return 'Network error. Please check your internet connection.';
      case AuthFailure:
        debugPrint('🔍 [AuthNotifier] Returning auth failure message: ${failure.message}');
        return failure.message;
      default:
        debugPrint('🔍 [AuthNotifier] Returning unexpected error message');
        return 'An unexpected error occurred.';
    }
  }
}

/// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier.fromServiceLocator();
});

/// Convenience providers for specific auth states
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).errorMessage;
});

final currentUserProvider = Provider<domain.User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
