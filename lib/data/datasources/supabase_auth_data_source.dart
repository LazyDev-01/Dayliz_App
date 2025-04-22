import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../../domain/entities/user.dart' as domain;
import '../models/user_model.dart';
import 'auth_data_source.dart';

/// Implementation of the AuthDataSource interface using Supabase
/// This class handles all authentication operations with Supabase
class SupabaseAuthDataSource implements AuthDataSource {
  final SupabaseClient _client;

  SupabaseAuthDataSource({required SupabaseClient client}) : _client = client;

  @override
  Future<domain.User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null || response.user == null) {
        throw app_exceptions.AuthException(message: 'Login failed');
      }

      // Convert Supabase user to domain user
      return _convertToDomainUser(response.user!);
    } on app_exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw app_exceptions.ServerException(message: 'Login failed: ${e.toString()}');
    }
  }

  @override
  Future<domain.User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      // Register the user
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      if (response.session == null || response.user == null) {
        throw app_exceptions.AuthException(message: 'Registration failed');
      }

      // Update user metadata
      await _client.from('users').upsert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Convert Supabase user to domain user
      return _convertToDomainUser(response.user!);
    } on app_exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw app_exceptions.ServerException(message: 'Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> logout() async {
    try {
      await _client.auth.signOut();
      return true;
    } catch (e) {
      throw app_exceptions.ServerException(message: 'Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<domain.User> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;

      if (user == null) {
        throw app_exceptions.AuthException(message: 'No user is logged in');
      }

      // Get additional user information from the database
      final userData = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      // Convert Supabase user to domain user
      return UserModel(
        id: user.id,
        name: userData['name'] ?? user.userMetadata?['name'] ?? '',
        email: user.email ?? '',
        phone: userData['phone'] ?? user.userMetadata?['phone'],
        createdAt: userData['created_at'] != null 
            ? DateTime.parse(userData['created_at']) 
            : (user.createdAt != null ? DateTime.parse(user.createdAt!) : null),
      );
    } on app_exceptions.AuthException {
      rethrow; 
    } catch (e) {
      throw app_exceptions.ServerException(message: 'Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final user = _client.auth.currentUser;
      final session = _client.auth.currentSession;
      
      return user != null && session != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> forgotPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      throw app_exceptions.ServerException(message: 'Failed to send password reset email: ${e.toString()}');
    }
  }

  @override
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      throw app_exceptions.ServerException(message: 'Failed to reset password: ${e.toString()}');
    }
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First, validate the current password by signing in again
      final email = _client.auth.currentUser?.email;
      
      if (email == null) {
        throw app_exceptions.AuthException(message: 'No user is logged in');
      }
      
      // Try to sign in with current password
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      
      // If sign-in succeeded, update the password
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      return true;
    } catch (e) {
      throw app_exceptions.ServerException(message: 'Failed to change password: ${e.toString()}');
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      final session = _client.auth.currentSession;
      
      if (session == null) {
        throw app_exceptions.AuthException(message: 'No active session');
      }
      
      await _client.auth.refreshSession();
      
      final newSession = _client.auth.currentSession;
      
      if (newSession == null) {
        throw app_exceptions.AuthException(message: 'Failed to refresh session');
      }
      
      return newSession.accessToken;
    } catch (e) {
      throw app_exceptions.ServerException(message: 'Failed to refresh token: ${e.toString()}');
    }
  }

  // Helper method to convert Supabase user to domain user
  domain.User _convertToDomainUser(User supabaseUser) {
    return UserModel(
      id: supabaseUser.id,
      name: supabaseUser.userMetadata?['name'] ?? '',
      email: supabaseUser.email ?? '',
      phone: supabaseUser.userMetadata?['phone'],
      createdAt: supabaseUser.createdAt != null 
          ? DateTime.parse(supabaseUser.createdAt!) 
          : null,
    );
  }
} 