import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Future<bool> ensureUserExists() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('Cannot ensure user exists: Not authenticated');
        return false;
      }
      
      debugPrint('Checking if user exists in public.users table: ${user.id}');
      
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
        'name': user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User',
        'phone': user.phone,
        'created_at': DateTime.now().toIso8601String(),
        'last_login_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Successfully created user record in public.users table');
      return true;
    } catch (e) {
      debugPrint('Error ensuring user exists: $e');
      return false;
    }
  }
} 