import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user.dart';
import '../../core/error/exceptions.dart';
import 'auth_data_source.dart';

/// Local data source for authentication operations
abstract class AuthLocalDataSource implements AuthDataSource {
  /// Caches user data to local storage
  Future<bool> cacheUser(User user);

  /// Retrieves cached user data
  Future<User?> getCachedUser();

  /// Caches authentication token
  Future<bool> cacheToken(String token);

  /// Gets cached authentication token
  String? getCachedToken();

  /// Clears cached token
  Future<bool> clearToken();

  /// Clears cached user
  Future<bool> clearUser();
}

/// Implementation of [AuthLocalDataSource]
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String CACHED_USER_KEY = 'CACHED_USER';
  static const String AUTH_TOKEN_KEY = 'AUTH_TOKEN';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<bool> cacheUser(User user) async {
    return await sharedPreferences.setString(
      CACHED_USER_KEY,
      json.encode({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'phone': user.phone,
        'profile_image_url': user.profileImageUrl,
        'is_email_verified': user.isEmailVerified,
        'metadata': user.metadata,
      }),
    );
  }

  @override
  Future<User?> getCachedUser() async {
    final userStr = sharedPreferences.getString(CACHED_USER_KEY);
    if (userStr != null) {
      try {
        final userMap = json.decode(userStr) as Map<String, dynamic>;
        return User(
          id: userMap['id'],
          email: userMap['email'],
          name: userMap['name'],
          phone: userMap['phone'],
          profileImageUrl: userMap['profile_image_url'],
          isEmailVerified: userMap['is_email_verified'],
          metadata: userMap['metadata'],
        );
      } catch (e) {
        throw CacheException(message: 'Failed to parse cached user data');
      }
    }
    return null;
  }

  @override
  Future<bool> cacheToken(String token) async {
    return await sharedPreferences.setString(AUTH_TOKEN_KEY, token);
  }

  @override
  String? getCachedToken() {
    return sharedPreferences.getString(AUTH_TOKEN_KEY);
  }

  @override
  Future<bool> clearToken() async {
    return await sharedPreferences.remove(AUTH_TOKEN_KEY);
  }

  @override
  Future<bool> clearUser() async {
    return await sharedPreferences.remove(CACHED_USER_KEY);
  }

  @override
  Future<User> login(String email, String password) async {
    // Not implemented in local data source
    throw UnimplementedError('Login not implemented in local data source');
  }

  @override
  Future<User> register(String email, String password, String name, {String? phone}) async {
    // Not implemented in local data source
    throw UnimplementedError('Register not implemented in local data source');
  }

  @override
  Future<bool> logout() async {
    await clearUser();
    await clearToken();
    return true;
  }

  @override
  Future<User?> getCurrentUser() async {
    return await getCachedUser();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = getCachedToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> forgotPassword(String email) async {
    // Not implemented in local data source
    throw UnimplementedError('Forgot password not implemented in local data source');
  }

  @override
  Future<bool> resetPassword({required String token, required String newPassword}) async {
    // Not implemented in local data source
    throw UnimplementedError('Reset password not implemented in local data source');
  }

  @override
  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    // Not implemented in local data source
    throw UnimplementedError('Change password not implemented in local data source');
  }

  @override
  Future<String> refreshToken() async {
    // Not implemented in local data source
    throw UnimplementedError('Refresh token not implemented in local data source');
  }

  @override
  Future<User> signInWithGoogle() async {
    // Not implemented in local data source
    throw UnimplementedError('Sign in with Google not implemented in local data source');
  }
}