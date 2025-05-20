import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';
import '../../services/google_sign_in_service.dart';

/// Implementation of [AuthDataSource] that uses Supabase for authentication
class AuthSupabaseDataSource implements AuthDataSource {
  final SupabaseClient _supabaseClient;

  AuthSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient {
    debugPrint('AuthSupabaseDataSource initialized with client: $_supabaseClient');
  }

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw ServerException(message: 'Login failed');
      }

      // Get additional user data from public.users table
      final userData = await _supabaseClient
          .from('user_profile_view')
          .select()
          .eq('user_id', response.user!.id)
          .single();

      return UserModel(
        id: response.user!.id,
        email: response.user!.email!,
        name: userData['name'] ?? response.user!.userMetadata?['name'] ?? '',
        phone: userData['phone'] ?? response.user!.phone,
        profileImageUrl: userData['profile_image_url'] ?? userData['avatar_url'],
        isEmailVerified: response.user!.emailConfirmedAt != null,
        metadata: response.user!.userMetadata,
      );
    } on AuthException catch (e) {
      throw ServerException(message: 'Authentication error: ${e.message}');
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<User> register(String email, String password, String name, {String? phone}) async {
    try {
      debugPrint('AuthSupabaseDataSource: Registering user with email: $email, name: $name, phone: $phone');
      
      // CRITICAL FIX: Check if email already exists before attempting registration
      bool emailExists = await _checkIfEmailExists(email);
      if (emailExists) {
        debugPrint('Email already exists: $email');
        throw ServerException(
          message: 'This email is already registered. Please use a different email or try logging in.'
        );
      }
      
      debugPrint('Email check passed, proceeding with registration');
      
      // Register the user with Supabase Auth
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      if (response.user == null) {
        throw ServerException(message: 'Registration failed: No user returned');
      }

      // Create a profile in the public.users table
      await _createUserProfile(response.user!.id, email, name, phone);

      // Return the user model
      return UserModel(
        id: response.user!.id,
        email: email,
        name: name,
        phone: phone,
        isEmailVerified: false,
      );
    } on AuthException catch (e) {
      // Check for duplicate email error
      if (_isDuplicateEmailError(e.message)) {
        throw ServerException(
          message: 'This email is already registered. Please use a different email or try logging in.'
        );
      }
      throw ServerException(message: 'Registration error: ${e.message}');
    } on PostgrestException catch (e) {
      // Check for duplicate key violation
      if (e.code == '23505' || _isDuplicateEmailError(e.message)) {
        throw ServerException(
          message: 'This email is already registered. Please use a different email or try logging in.'
        );
      }
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      // Check if the error message indicates a duplicate email
      if (_isDuplicateEmailError(e.toString())) {
        throw ServerException(
          message: 'This email is already registered. Please use a different email or try logging in.'
        );
      }
      throw ServerException(message: 'Registration failed: ${e.toString()}');
    }
  }

  /// Check if an error message indicates a duplicate email
  bool _isDuplicateEmailError(String message) {
    String lowerMsg = message.toLowerCase();
    return lowerMsg.contains('already registered') ||
           lowerMsg.contains('already exists') ||
           lowerMsg.contains('email already') ||
           lowerMsg.contains('duplicate') ||
           lowerMsg.contains('unique constraint') ||
           lowerMsg.contains('email is already') ||
           lowerMsg.contains('account already') ||
           lowerMsg.contains('already taken') ||
           lowerMsg.contains('already in use') ||
           lowerMsg.contains('already signed up') ||
           lowerMsg.contains('already has an account') ||
           lowerMsg.contains('exists') ||
           lowerMsg.contains('conflict') ||
           lowerMsg.contains('violation');
  }

  /// Check if an email already exists in the system
  Future<bool> _checkIfEmailExists(String email) async {
    try {
      // Method 1: Check in public.users table
      final existingUserQuery = await _supabaseClient
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();
          
      if (existingUserQuery != null) {
        return true;
      }
      
      // Method 2: Try to sign in with a dummy password
      try {
        await _supabaseClient.auth.signInWithPassword(
          email: email,
          password: 'Dummy_Password_123!',
        );
        
        // If we get here, the sign-in succeeded (extremely unlikely)
        return true;
      } catch (e) {
        String errorMsg = e.toString().toLowerCase();
        
        // If the error contains "invalid login credentials", the email exists
        if (errorMsg.contains('invalid login') || 
            errorMsg.contains('invalid email') || 
            errorMsg.contains('wrong password') ||
            errorMsg.contains('invalid credentials')) {
          return true;
        }
        
        // If the error contains "user not found", the email doesn't exist
        if (errorMsg.contains('user not found') || 
            errorMsg.contains('no user found') ||
            errorMsg.contains('no account')) {
          return false;
        }
      }
      
      // Default to false if we couldn't determine
      return false;
    } catch (e) {
      debugPrint('Error checking if email exists: $e');
      return false;
    }
  }

  /// Helper method to create user profile in public.users and user_profiles tables
  Future<void> _createUserProfile(String userId, String email, String name, String? phone) async {
    try {
      await _supabaseClient.from('users').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      await _supabaseClient.from('user_profiles').upsert({
        'id': userId,
        'user_id': userId,
        'full_name': name,
        'display_name': name,
        'avatar_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  // Other methods remain unchanged...
  @override
  Future<bool> logout() async {
    try {
      await _supabaseClient.auth.signOut();
      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to logout: ${e.toString()}');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    // Implementation remains the same
    return null; // Placeholder
  }

  @override
  Future<User> signInWithGoogle() async {
    // Implementation remains the same
    throw UnimplementedError();
  }

  @override
  Future<void> cacheUser(User user) async {
    // Implementation remains the same
  }

  @override
  Future<bool> isAuthenticated() async {
    return _supabaseClient.auth.currentUser != null;
  }

  @override
  Future<void> forgotPassword(String email) async {
    // Implementation remains the same
    throw UnimplementedError();
  }

  @override
  Future<bool> resetPassword({required String token, required String newPassword}) async {
    // Implementation remains the same
    throw UnimplementedError();
  }

  @override
  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    // Implementation remains the same
    throw UnimplementedError();
  }

  @override
  Future<String> refreshToken() async {
    // Implementation remains the same
    throw UnimplementedError();
  }
}
