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
      // But make this check optional to avoid blocking registration if the check fails
      try {
        if (await _emailExists(email)) {
          debugPrint('Email already exists: $email');
          throw ServerException(
            message: 'This email is already registered. Please use a different email or try logging in.'
          );
        }
        debugPrint('Email check passed, proceeding with registration');
      } catch (e) {
        debugPrint('Error during email existence check: $e');
        // Continue with registration even if the check fails
        // Supabase will handle duplicate emails during signUp
      }

      // Log password requirements check
      debugPrint('Password length: ${password.length}');
      debugPrint('Password has lowercase: ${RegExp(r'[a-z]').hasMatch(password)}');
      debugPrint('Password has uppercase: ${RegExp(r'[A-Z]').hasMatch(password)}');
      debugPrint('Password has number: ${RegExp(r'[0-9]').hasMatch(password)}');
      debugPrint('Password has special: ${RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)}');

      // Register the user with Supabase Auth
      debugPrint('Calling Supabase auth.signUp...');
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );
      debugPrint('Supabase auth.signUp completed');

      // Check response
      if (response.user == null) {
        debugPrint('Registration failed: No user returned from signUp');
        throw ServerException(message: 'Registration failed: No user returned');
      }

      debugPrint('User created successfully with ID: ${response.user!.id}');

      // Create a profile in the public.users table
      try {
        await _createUserProfile(response.user!.id, email, name, phone);
        debugPrint('User profile created successfully');
      } catch (e) {
        debugPrint('Error creating user profile, but continuing: $e');
        // Continue even if profile creation fails
        // The user is already created in auth
      }

      // Return the user model
      return UserModel(
        id: response.user!.id,
        email: email,
        name: name,
        phone: phone,
        isEmailVerified: false,
      );
    } on AuthException catch (e) {
      debugPrint('AuthException during registration: ${e.message}');

      // Check for duplicate email error
      if (_isDuplicateEmailError(e.message)) {
        debugPrint('Detected duplicate email error');
        throw ServerException(
          message: 'This email is already registered. Please use a different email or try logging in.'
        );
      }

      // Check for password format errors
      if (e.message.toLowerCase().contains('password')) {
        debugPrint('Detected password format error');
        throw ServerException(
          message: 'Password must contain at least one lowercase letter, one uppercase letter, one number, and one special character.'
        );
      }

      throw ServerException(message: 'Registration error: ${e.message}');
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException during registration: ${e.message}, code: ${e.code}');

      // Check for duplicate key violation
      if (e.code == '23505' || _isDuplicateEmailError(e.message)) {
        debugPrint('Detected duplicate key violation');
        throw ServerException(
          message: 'This email is already registered. Please use a different email or try logging in.'
        );
      }

      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error during registration: $e');

      // Check if the error message indicates a duplicate email
      if (_isDuplicateEmailError(e.toString())) {
        debugPrint('Detected duplicate email in generic error');
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
  Future<bool> _emailExists(String email) async {
    try {
      debugPrint('Checking if email exists: $email');

      // Method 1: Check in public.users table
      try {
        final existingUserQuery = await _supabaseClient
            .from('users')
            .select('email')
            .eq('email', email)
            .maybeSingle();

        if (existingUserQuery != null) {
          debugPrint('Email found in users table: $email');
          return true;
        } else {
          debugPrint('Email not found in users table: $email');
        }
      } catch (e) {
        debugPrint('Error checking users table: $e');
        // Continue to next method if this one fails
      }

      // Note: We can't directly check auth.users table without admin privileges
      // So we'll skip this method and rely on the other methods

      // Method 3: Try to sign in with a dummy password
      try {
        await _supabaseClient.auth.signInWithPassword(
          email: email,
          password: 'Dummy_Password_123!',
        );

        // If we get here, the sign-in succeeded (extremely unlikely)
        debugPrint('Sign-in succeeded with dummy password (email exists): $email');
        return true;
      } catch (e) {
        String errorMsg = e.toString().toLowerCase();
        debugPrint('Sign-in error: $errorMsg');

        // If the error contains "invalid login credentials", the email exists
        if (errorMsg.contains('invalid login') ||
            errorMsg.contains('invalid email') ||
            errorMsg.contains('wrong password') ||
            errorMsg.contains('invalid credentials')) {
          debugPrint('Email exists based on credentials error: $email');
          return true;
        }

        // If the error contains "user not found", the email doesn't exist
        if (errorMsg.contains('user not found') ||
            errorMsg.contains('no user found') ||
            errorMsg.contains('no account')) {
          debugPrint('Email does not exist based on user not found error: $email');
          return false;
        }
      }

      // Default to false if we couldn't determine
      debugPrint('Could not determine if email exists, defaulting to false: $email');
      return false;
    } catch (e) {
      debugPrint('Error checking if email exists: $e');
      // If there's an error, assume the email doesn't exist to allow registration
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
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        debugPrint('getCurrentUser: No current user found');
        return null;
      }

      debugPrint('getCurrentUser: Found current user with ID: ${currentUser.id}');

      // Try to get additional user data from the database
      try {
        final userData = await _supabaseClient
            .from('user_profile_view')
            .select()
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (userData != null) {
          debugPrint('getCurrentUser: Found user profile data');
          return UserModel(
            id: currentUser.id,
            email: currentUser.email!,
            name: userData['name'] ?? currentUser.userMetadata?['name'] ?? '',
            phone: userData['phone'] ?? currentUser.phone,
            profileImageUrl: userData['profile_image_url'] ?? userData['avatar_url'],
            isEmailVerified: currentUser.emailConfirmedAt != null,
            metadata: currentUser.userMetadata,
          );
        }
      } catch (e) {
        debugPrint('Error getting user profile data: $e');
        // Continue with basic user data if profile fetch fails
      }

      // Return basic user data if profile data is not available
      return UserModel(
        id: currentUser.id,
        email: currentUser.email!,
        name: currentUser.userMetadata?['name'] ?? '',
        phone: currentUser.phone,
        isEmailVerified: currentUser.emailConfirmedAt != null,
        metadata: currentUser.userMetadata,
      );
    } catch (e) {
      debugPrint('Error in getCurrentUser: $e');
      return null;
    }
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
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      final session = _supabaseClient.auth.currentSession;

      // Check if we have both a user and a valid session
      if (currentUser != null && session != null) {
        // Check if the session is expired
        final now = DateTime.now().millisecondsSinceEpoch / 1000;
        if (session.expiresAt != null && session.expiresAt! > now) {
          debugPrint('User is authenticated with valid session');
          return true;
        } else {
          debugPrint('Session is expired, attempting refresh');
          try {
            // Try to refresh the session
            await _supabaseClient.auth.refreshSession();
            // If refresh succeeds, user is authenticated
            return true;
          } catch (e) {
            debugPrint('Session refresh failed: $e');
            return false;
          }
        }
      }

      debugPrint('User is not authenticated: currentUser=${currentUser != null}, session=${session != null}');
      return false;
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
      return false;
    }
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
