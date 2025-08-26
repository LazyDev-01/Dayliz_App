import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/user.dart';
import '../../core/errors/exceptions.dart';
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
  final FlutterSecureStorage _secureStorage;
  static const String CACHED_USER_KEY = 'CACHED_USER';
  static const String AUTH_TOKEN_KEY = 'AUTH_TOKEN';

  AuthLocalDataSourceImpl({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  @override
  Future<bool> cacheUser(User user) async {
    try {
      await _secureStorage.write(
        key: CACHED_USER_KEY,
        value: json.encode({
          'id': user.id,
          'email': user.email,
          'name': user.name,
          'phone': user.phone,
          'profile_image_url': user.profileImageUrl,
          'is_email_verified': user.isEmailVerified,
          'metadata': user.metadata,
        }),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<User?> getCachedUser() async {
    try {
      final userStr = await _secureStorage.read(key: CACHED_USER_KEY);
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
    } catch (e) {
      throw CacheException(message: 'Failed to read cached user data');
    }
  }

  @override
  Future<bool> cacheToken(String token) async {
    try {
      await _secureStorage.write(key: AUTH_TOKEN_KEY, value: token);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String? getCachedToken() {
    // Note: FlutterSecureStorage read is async, but this method signature is sync
    // We'll need to handle this differently - for now, return null and use async version
    return null;
  }

  /// Async version of getCachedToken for secure storage
  Future<String?> getCachedTokenAsync() async {
    try {
      return await _secureStorage.read(key: AUTH_TOKEN_KEY);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> clearToken() async {
    try {
      await _secureStorage.delete(key: AUTH_TOKEN_KEY);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> clearUser() async {
    try {
      await _secureStorage.delete(key: CACHED_USER_KEY);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<User> login(String email, String password) async {
    // Local data source doesn't handle login - return cached user if available
    final cachedUser = await getCachedUser();
    if (cachedUser != null) {
      return cachedUser;
    }
    throw CacheException(message: 'No cached user found for login');
  }

  @override
  Future<User> register(String email, String password, String name, {String? phone}) async {
    // Local data source doesn't handle registration
    throw CacheException(message: 'Registration not supported in local data source');
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
    final token = await getCachedTokenAsync();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> forgotPassword(String email) async {
    // Local data source doesn't handle password operations
    throw CacheException(message: 'Forgot password not supported in local data source');
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    // Local data source doesn't handle email existence checks
    throw CacheException(message: 'Email existence check not supported in local data source');
  }

  @override
  Future<bool> resetPassword({required String token, required String newPassword}) async {
    // Local data source doesn't handle password operations
    throw CacheException(message: 'Reset password not supported in local data source');
  }

  @override
  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    // Local data source doesn't handle password operations
    throw CacheException(message: 'Change password not supported in local data source');
  }

  @override
  Future<String> refreshToken() async {
    // Return cached token if available
    final token = await getCachedTokenAsync();
    if (token != null && token.isNotEmpty) {
      return token;
    }
    throw CacheException(message: 'No cached token found');
  }

  @override
  Future<User> signInWithGoogle() async {
    // Local data source doesn't handle Google sign-in
    throw CacheException(message: 'Google sign-in not supported in local data source');
  }
}