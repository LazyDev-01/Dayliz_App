import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// Service that handles user operations using Supabase.
class UserService {
  static final UserService _instance = UserService._internal();
  static UserService get instance => _instance;
  
  late final SupabaseClient _client;
  
  /// Private constructor
  UserService._internal() {
    _client = Supabase.instance.client;
  }
  
  /// Get the current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final userId = _client.auth.currentUser?.id;
      return userId;
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }
  
  /// Get the current user
  User? getCurrentUser() {
    try {
      return _client.auth.currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }
  
  /// Check if user is signed in
  bool isSignedIn() {
    return _client.auth.currentUser != null;
  }
  
  /// Ensure the current user exists in the public.users table
  /// This is required for foreign key relationships to work
  /// Returns true if user exists or was created successfully
  Future<bool> ensureUserExists() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('Cannot ensure user exists: Not authenticated');
        return false;
      }
      
      debugPrint('Checking if user exists in public.users table: ${user.id}');
      
      // First try direct SQL insert
      try {
        final email = user.email ?? '';
        
        // Create user directly using SQL to bypass RLS
        final createUserSQL = '''
        INSERT INTO public.users (id, email, created_at, updated_at)
        VALUES ('${user.id}', '$email', NOW(), NOW())
        ON CONFLICT (id) DO NOTHING;
        ''';
        
        await _client.rpc('execute_sql', params: {'query': createUserSQL});
        debugPrint('Successfully attempted to create user via direct SQL');
        
        // Also create a user profile
        try {
          final fullName = user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User';
          final createProfileSQL = '''
          INSERT INTO public.user_profiles (user_id, full_name, created_at, updated_at)
          VALUES ('${user.id}', '$fullName', NOW(), NOW())
          ON CONFLICT (user_id) DO NOTHING;
          ''';
          
          await _client.rpc('execute_sql', params: {'query': createProfileSQL});
          debugPrint('Successfully attempted to create user profile via direct SQL');
        } catch (e) {
          debugPrint('Error creating user profile via SQL: $e');
        }
        
        return true;
      } catch (sqlError) {
        debugPrint('Error creating user via SQL: $sqlError');
      }
      
      // Try up to 3 times in case of temporary issues
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          // Check if user exists in public.users table
          final existingUser = await _client
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          
          // If user exists, return true
          if (existingUser != null) {
            debugPrint('User already exists in public.users table');
            return true;
          }
          
          // User doesn't exist, create a new record
          debugPrint('User does not exist in public.users table, creating record...');
          
          // Create user record with auth user data
          await _client.from('users').insert({
            'id': user.id,
            'email': user.email,
            'phone': user.phone,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          // Also create a user profile entry
          try {
            await _client.from('user_profiles').insert({
              'user_id': user.id,
              'full_name': user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            debugPrint('Successfully created user profile record');
          } catch (profileError) {
            debugPrint('Warning: Could not create user profile: $profileError');
            // Continue even if profile creation fails
          }
          
          debugPrint('Successfully created user record in public.users table');
          return true;
        } on PostgrestException catch (e) {
          // Handle specific Postgres errors
          if (e.code == '23505') { // Unique violation (duplicate key) 
            debugPrint('User record already exists (concurrent creation). Using existing record.');
            return true;
          } else if (attempt < 3) {
            // Wait before retrying for other types of errors
            debugPrint('Attempt $attempt failed: ${e.message}. Retrying...');
            await Future.delayed(Duration(seconds: 1 * attempt));
            continue;
          } else {
            // Last attempt failed
            debugPrint('Error ensuring user exists after $attempt attempts: ${e.code} - ${e.message}');
            return false;
          }
        }
      }
      
      // All attempts failed
      return false;
    } catch (e) {
      debugPrint('Unexpected error ensuring user exists: $e');
      return false;
    }
  }
  
  /// Update user's profile information in the users table
  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('Cannot update profile: Not authenticated');
        return false;
      }
      
      // Update user basic info in users table
      final Map<String, dynamic> userUpdateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (phone != null) userUpdateData['phone'] = phone;
      
      if (userUpdateData.length > 1) { // Only if we have more than just updated_at
        await _client.from('users').update(userUpdateData).eq('id', user.id);
        debugPrint('Successfully updated basic user info');
      }
      
      // Update profile info in user_profiles table
      final Map<String, dynamic> profileUpdateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (name != null) profileUpdateData['full_name'] = name;
      if (avatarUrl != null) profileUpdateData['avatar_url'] = avatarUrl;
      
      if (profileUpdateData.length > 1) { // Only if we have more than just updated_at
        await _client.from('user_profiles').update(profileUpdateData).eq('user_id', user.id);
        debugPrint('Successfully updated user profile');
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }
} 