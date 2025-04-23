import 'package:dartz/dartz.dart';
import '../entities/user.dart' as domain;
import '../../core/errors/failures.dart';

/// Authentication repository interface defining methods for auth operations
abstract class AuthRepository {
  /// Login a user with email and password
  /// Returns a [Either] with a [Failure] or a [User] entity
  Future<Either<Failure, domain.User>> login({
    required String email,
    required String password,
    bool rememberMe = true,
  });

  /// Sign in with Google
  /// Returns a [Either] with a [Failure] or a [User] entity
  Future<Either<Failure, domain.User>> signInWithGoogle();

  /// Register a new user
  /// Returns a [Either] with a [Failure] or a [User] entity
  Future<Either<Failure, domain.User>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  /// Logout the current user
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> logout();

  /// Get the current authenticated user
  /// Returns a [Either] with a [Failure] or a [User] entity
  Future<Either<Failure, domain.User>> getCurrentUser();

  /// Check if a user is authenticated
  /// Returns a [bool] indicating if the user is authenticated
  Future<bool> isAuthenticated();

  /// Send a password reset email
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> forgotPassword({
    required String email,
  });

  /// Reset password with token
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Change password for authenticated user
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Refresh authentication token
  /// Returns a [Either] with a [Failure] or a [String] containing the new token
  Future<Either<Failure, String>> refreshToken();
}