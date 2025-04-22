import '../../domain/entities/user.dart';

/// Interface for auth data sources
abstract class AuthDataSource {
  /// Login a user with email and password
  Future<User> login(String email, String password);

  /// Register a new user
  Future<User> register(String email, String password, String name);

  /// Logout the current user
  Future<void> logout();

  /// Get the current authenticated user
  Future<User?> getCurrentUser();

  /// Check if a user is authenticated
  Future<bool> isAuthenticated();

  /// Send a password reset email
  Future<void> forgotPassword(String email);

  /// Reset password with token and new password
  /// Returns a [bool] indicating success
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Change password with current and new password
  /// Returns a [bool] indicating success
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Refresh the authentication token
  /// Returns a [String] containing the new token
  Future<String> refreshToken();

  /// Cache the user locally
  Future<void> cacheUser(User user);
} 