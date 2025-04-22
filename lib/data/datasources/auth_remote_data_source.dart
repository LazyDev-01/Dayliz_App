import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/error/exceptions.dart';
import '../../core/constants/api_endpoints.dart';
import '../../domain/entities/user.dart';
import 'auth_data_source.dart';

/// Interface for the authentication remote data source
abstract class AuthRemoteDataSource {
  /// Sign in with email and password
  /// Returns the signed in user
  /// Throws [Exception] on error
  Future<User> login(String email, String password);

  /// Register a new user
  /// Returns the newly registered user
  /// Throws [Exception] on error
  Future<User> register(String email, String password, String name);

  /// Sign out the current user
  /// Returns true on success
  /// Throws [Exception] on error
  Future<void> logout();

  /// Get the current authenticated user
  /// Returns the current user or throws [Exception] if no user is authenticated
  Future<User?> getCurrentUser();

  /// Check if a user is authenticated
  /// Returns true if a user is authenticated
  Future<bool> isAuthenticated();

  /// Send a password reset email
  /// Returns true on success
  /// Throws [Exception] on error
  Future<void> forgotPassword(String email);

  /// Reset the password with a token
  /// Returns true on success
  /// Throws [Exception] on error
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Change the password for the authenticated user
  /// Returns true on success
  /// Throws [Exception] on error
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Refresh the authentication token
  /// Returns the new token
  /// Throws [Exception] on error
  Future<String> refreshToken();

  /// Cache a user
  /// Returns true on success
  /// Throws [Exception] on error
  Future<void> cacheUser(User user);
}

/// Implementation of [AuthDataSource] that communicates with the remote API
class AuthRemoteDataSourceImpl implements AuthDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<User> login(String email, String password) async {
    // Mock implementation for now
    return User(
      id: '1',
      email: email,
      name: 'Test User',
    );
  }

  @override
  Future<User> register(String email, String password, String name) async {
    // Mock implementation for now
    return User(
      id: '1',
      email: email,
      name: name,
    );
  }

  @override
  Future<bool> logout() async {
    // Mock implementation for now
    return true;
  }

  @override
  Future<User?> getCurrentUser() async {
    // Mock implementation for now
    return User(
      id: '1',
      email: 'test@example.com',
      name: 'Test User',
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    // Mock implementation for now
    return true;
  }

  @override
  Future<void> forgotPassword(String email) async {
    // Mock implementation for now
    return;
  }

  @override
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    // This functionality might need to be added to the AuthService
    // For now, return successful mock response
    return true;
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // This functionality might need to be added to the AuthService
    // For now, return successful mock response
    return true;
  }

  @override
  Future<String> refreshToken() async {
    // Return a mock token
    return 'mock_token_12345';
  }
  
  @override
  Future<void> cacheUser(User user) async {
    // For remote data source, caching might not apply directly
    // This is typically handled by the local data source
    // However, we need to implement it to satisfy the interface
    
    // No-op implementation as the remote data source doesn't handle caching
    return;
  }
} 