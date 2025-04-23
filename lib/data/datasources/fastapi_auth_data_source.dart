import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart' as domain;
import '../models/user_model.dart';
import 'auth_data_source.dart';

/// Implementation of the AuthDataSource interface using FastAPI
/// This class serves as a placeholder for the eventual FastAPI integration
/// To be fully implemented post-launch
class FastAPIAuthDataSource implements AuthDataSource {
  final http.Client _client;
  final String _baseUrl;
  String? _token;

  FastAPIAuthDataSource({
    required http.Client client,
    required String baseUrl,
  }) : _client = client,
       _baseUrl = baseUrl;

  // Helper method to create authenticated request headers
  Map<String, String> _getAuthHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  @override
  Future<domain.User> login({
    required String email,
    required String password,
  }) async {
    // TODO: Implement FastAPI login after post-launch
    throw UnimplementedError('FastAPI integration not yet implemented');

    /* IMPLEMENTATION GUIDE
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['access_token'];

        return UserModel.fromJson(responseData['user']);
      } else {
        throw AuthException('Login failed: ${response.body}');
      }
    } catch (e) {
      throw ServerException(message: 'Login failed: ${e.toString()}');
    }
    */
  }

  @override
  Future<domain.User> register(String email, String password, String name, {String? phone}) async {
    // TODO: Implement FastAPI registration after post-launch
    throw UnimplementedError('FastAPI integration not yet implemented');

    /* IMPLEMENTATION GUIDE
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        _token = responseData['access_token'];

        return UserModel.fromJson(responseData['user']);
      } else {
        throw AuthException('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw ServerException(message: 'Registration failed: ${e.toString()}');
    }
    */
  }

  @override
  Future<bool> logout() async {
    // TODO: Implement FastAPI logout after post-launch
    throw UnimplementedError('FastAPI integration not yet implemented');

    /* IMPLEMENTATION GUIDE
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        _token = null;
        return true;
      } else {
        throw ServerException(message: 'Logout failed: ${response.body}');
      }
    } catch (e) {
      throw ServerException(message: 'Logout failed: ${e.toString()}');
    }
    */
  }

  @override
  Future<domain.User> getCurrentUser() async {
    // TODO: Implement FastAPI getCurrentUser after post-launch
    throw UnimplementedError('FastAPI integration not yet implemented');

    /* IMPLEMENTATION GUIDE
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return UserModel.fromJson(responseData);
      } else {
        throw AuthException('Failed to get current user: ${response.body}');
      }
    } catch (e) {
      throw ServerException(message: 'Failed to get current user: ${e.toString()}');
    }
    */
  }

  @override
  Future<bool> isAuthenticated() async {
    // TODO: Implement FastAPI isAuthenticated after post-launch
    return false; // Default to not authenticated until implemented
  }

  @override
  Future<void> forgotPassword(String email) async {
    // TODO: Implement FastAPI forgotPassword after post-launch
    throw UnimplementedError('FastAPI integration not yet implemented');
  }

  @override
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    // TODO: Implement FastAPI resetPassword after post-launch
    throw UnimplementedError('FastAPI integration not yet implemented');
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // TODO: Implement FastAPI changePassword after post-launch
    throw UnimplementedError('FastAPI integration not yet implemented');
  }

  @override
  Future<String> refreshToken() async {
    // TODO: Implement FastAPI refreshToken after post-launch
    throw UnimplementedError('FastAPI integration not yet implemented');
  }
}