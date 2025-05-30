import '../../domain/entities/user.dart';

/// Interface for auth data sources
abstract class AuthDataSource {
  /// Login a user with email and password
  Future<User> login(String email, String password);

  /// Sign in with Google
  Future<User> signInWithGoogle();

  /// Register a new user
  Future<User> register(String email, String password, String name, {String? phone});

  /// Logout the current user
  Future<bool> logout();

  /// Get the current authenticated user
  Future<User?> getCurrentUser();

  /// Check if a user is authenticated
  Future<bool> isAuthenticated();

  /// Send a password reset email
  Future<void> forgotPassword(String email);

  /// Check if an email already exists in the system
  Future<bool> checkEmailExists(String email);

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

/// Interface for remote authentication data sources
abstract class AuthRemoteDataSource extends AuthDataSource {}

/// Interface for local authentication data sources
abstract class AuthLocalDataSource {
  /// Caches a user locally
  Future<void> cacheUser(User user);

  /// Gets the cached user
  Future<User?> getCachedUser();

  /// Clears the cached user
  Future<bool> clearCachedUser();
}