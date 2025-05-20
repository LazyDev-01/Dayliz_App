import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../core/error/exceptions.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';
import '../../services/google_sign_in_service.dart';

/// Implementation of [AuthDataSource] that uses Supabase for authentication
class AuthSupabaseDataSource implements AuthDataSource {
  final SupabaseClient _supabaseClient;

  AuthSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

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
      // Check if email already exists before attempting registration
      bool emailExists = await _checkIfEmailExists(email);
      if (emailExists) {
        throw ServerException(
          message: 'This email is already registered. Please use a different email or try logging in.'
        );
      }

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

      // IMPORTANT: In Supabase, the user is created in auth.users table automatically
      // Now we need to create a profile in the public.users table
      await _createUserProfile(response.user!.id, email, name, phone);

      // Return the user model
      return UserModel(
        id: response.user!.id,
        email: email,
        name: name,
        phone: phone,
        isEmailVerified: false,
      );
    } on AuthException catch (e, stackTrace) {
      debugPrint('Supabase Auth Error: ${e.message}');
      debugPrint('Error code: ${e.statusCode}');
      debugPrint('Stack trace: $stackTrace');

      // CRITICAL FIX: Always check for duplicate email first
      // This is the most common error during registration

      // Convert message to lowercase for case-insensitive comparison
      String lowerCaseMsg = e.message.toLowerCase();

      // Comprehensive check for ANY indication of duplicate email
      if (lowerCaseMsg.contains('user already registered') ||
          lowerCaseMsg.contains('already exists') ||
          lowerCaseMsg.contains('email already') ||
          lowerCaseMsg.contains('duplicate') ||
          lowerCaseMsg.contains('unique constraint') ||
          lowerCaseMsg.contains('email is already') ||
          lowerCaseMsg.contains('account already') ||
          lowerCaseMsg.contains('already registered') ||
          lowerCaseMsg.contains('already taken') ||
          lowerCaseMsg.contains('already in use') ||
          lowerCaseMsg.contains('already signed up') ||
          lowerCaseMsg.contains('already has an account') ||
          lowerCaseMsg.contains('exists') ||
          lowerCaseMsg.contains('conflict') ||
          lowerCaseMsg.contains('violation')) {

        debugPrint('Detected duplicate email error: ${e.message}');
        throw ServerException(message: 'This email is already registered. Please use a different email or try logging in.');
      }
      // Check for password format issues
      else if (lowerCaseMsg.contains('password should') ||
               lowerCaseMsg.contains('password requirements') ||
               lowerCaseMsg.contains('password must')) {
        throw ServerException(message: 'Password must contain at least one lowercase letter, one uppercase letter, one number, and one special character.');
      }
      // Check for invalid email format
      else if (lowerCaseMsg.contains('invalid email') ||
               lowerCaseMsg.contains('email format')) {
        throw ServerException(message: 'Please enter a valid email address.');
      }
      // Check for database errors that might indicate a duplicate
      else if (lowerCaseMsg.contains('unexpected_failure') ||
               lowerCaseMsg.contains('database error saving new user') ||
               lowerCaseMsg.contains('conflict')) {
        // This is the specific error we're seeing
        // Wait a moment to ensure auth is complete
        await Future.delayed(const Duration(seconds: 1));
        // Check if we have a user despite the error
        final currentUser = _supabaseClient.auth.currentUser;
        if (currentUser != null) {
          debugPrint('Auth succeeded despite error. Returning auth user.');

          // Try to create the user profile
          await _createUserProfile(currentUser.id, email, name, phone);

          return UserModel(
            id: currentUser.id,
            email: email,
            name: name,
            phone: phone,
            isEmailVerified: false,
          );
        }
        throw ServerException(message: 'Registration failed. Please try again with a different email or password.');
      } else {
        throw ServerException(message: 'Registration error: ${e.message}');
      }
    } on PostgrestException catch (e, stackTrace) {
      debugPrint('Supabase Database Error: ${e.message}');
      debugPrint('Error code: ${e.code}');
      debugPrint('Stack trace: $stackTrace');

      // Convert message to lowercase for case-insensitive comparison
      String lowerCaseMsg = e.message.toLowerCase();

      // Check for duplicate key violations (email uniqueness constraint)
      if (e.code == '23505' || // PostgreSQL unique violation code
          lowerCaseMsg.contains('duplicate') ||
          lowerCaseMsg.contains('unique constraint') ||
          lowerCaseMsg.contains('already exists') ||
          lowerCaseMsg.contains('violates unique') ||
          lowerCaseMsg.contains('duplicate key') ||
          lowerCaseMsg.contains('conflict') ||
          lowerCaseMsg.contains('already registered') ||
          lowerCaseMsg.contains('email already')) {
        debugPrint('Detected duplicate email error in database: ${e.message}');
        throw ServerException(message: 'This email is already registered. Please use a different email or try logging in.');
      }

      // For any other PostgrestException, check if we have a user in auth
      // Wait a moment to ensure auth is complete
      await Future.delayed(const Duration(seconds: 1));
      // If we do, return that user and ignore the database error
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser != null) {
        debugPrint('Database error, but auth user exists. Returning auth user.');

        // Try to create the user profile
        await _createUserProfile(currentUser.id, email, name, phone);

        return UserModel(
          id: currentUser.id,
          email: email,
          name: name,
          phone: phone,
          isEmailVerified: false,
        );
      }

      // If no auth user, throw a generic error
      throw ServerException(message: 'Registration failed. Please try again with a different email or password.');
    } catch (e, stackTrace) {
      debugPrint('Unexpected Error: ${e.toString()}');
      debugPrint('Stack trace: $stackTrace');

      // Check if the error message indicates a duplicate email
      String errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('duplicate') ||
          errorMsg.contains('already exists') ||
          errorMsg.contains('already registered') ||
          errorMsg.contains('email already') ||
          errorMsg.contains('unique constraint') ||
          errorMsg.contains('conflict')) {
        debugPrint('Detected duplicate email error in generic catch: $errorMsg');
        throw ServerException(message: 'This email is already registered. Please use a different email or try logging in.');
      }

      // For any other error, check if we have a user in auth
      // Wait a moment to ensure auth is complete
      await Future.delayed(const Duration(seconds: 1));
      // If we do, return that user and ignore the error
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser != null) {
        debugPrint('Error occurred, but auth user exists. Returning auth user.');

        // Try to create the user profile
        await _createUserProfile(currentUser.id, email, name, phone);

        return UserModel(
          id: currentUser.id,
          email: email,
          name: name,
          phone: phone,
          isEmailVerified: false,
        );
      }

      // If we get here, there's no auth user, so throw a generic error
      throw ServerException(message: 'Registration failed. Please try again with a different email or password.');
    }
  }

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
        return null;
      }

      // Get additional user data from public.users table
      final userData = await _supabaseClient
          .from('user_profile_view')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (userData == null) {
        // If no profile exists, try to create one
        debugPrint('No user profile found, attempting to create one');
        final name = currentUser.userMetadata?['name'] ?? '';
        final phone = currentUser.phone;
        await _createUserProfile(currentUser.id, currentUser.email!, name, phone);

        // Return basic user info from auth
        return UserModel(
          id: currentUser.id,
          email: currentUser.email!,
          name: currentUser.userMetadata?['name'] ?? '',
          isEmailVerified: currentUser.emailConfirmedAt != null,
          metadata: currentUser.userMetadata,
        );
      }

      return UserModel(
        id: currentUser.id,
        email: currentUser.email!,
        name: userData['name'] ?? currentUser.userMetadata?['name'] ?? '',
        phone: userData['phone'] ?? currentUser.phone,
        profileImageUrl: userData['avatar_url'],
        isEmailVerified: currentUser.emailConfirmedAt != null,
        metadata: currentUser.userMetadata,
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
  Future<User> signInWithGoogle() async {
    try {
      debugPrint('AuthSupabaseDataSource: Starting Google sign-in');

      // Get the GoogleSignInService instance
      final googleService = GoogleSignInService.instance;

      // Sign in with Google
      final response = await googleService.signIn();

      if (response.user == null) {
        throw ServerException(message: 'Google sign-in failed: No user returned');
      }

      debugPrint('AuthSupabaseDataSource: Google sign-in successful');

      // Get additional user data from public.users table
      final userData = await _supabaseClient
          .from('user_profile_view')
          .select()
          .eq('user_id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        // If no profile exists, create one
        final name = response.user!.userMetadata?['name'] ?? '';
        final email = response.user!.email!;
        final phone = response.user!.phone;

        await _createUserProfile(response.user!.id, email, name, phone);

        // Return basic user info
        return UserModel(
          id: response.user!.id,
          email: email,
          name: name,
          phone: phone,
          isEmailVerified: response.user!.emailConfirmedAt != null,
          metadata: response.user!.userMetadata,
        );
      }

      // Return user with profile data
      return UserModel(
        id: response.user!.id,
        email: response.user!.email!,
        name: userData['name'] ?? response.user!.userMetadata?['name'] ?? '',
        phone: userData['phone'] ?? response.user!.phone,
        profileImageUrl: userData['avatar_url'],
        isEmailVerified: response.user!.emailConfirmedAt != null,
        metadata: response.user!.userMetadata,
      );
    } catch (e) {
      debugPrint('AuthSupabaseDataSource: Error during Google sign-in: $e');
      throw ServerException(message: 'Google sign-in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheUser(User user) async {
    // This is intentionally left empty as caching is handled by AuthLocalDataSource
    // This implementation focuses only on remote operations
  }

  @override
  Future<bool> isAuthenticated() async {
    return _supabaseClient.auth.currentUser != null;
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw ServerException(message: 'Failed to send reset email: ${e.toString()}');
    }
  }

  @override
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      // For Supabase, we directly call updateUser as the token would be in the URL
      // when the user clicks the reset password link
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to reset password: ${e.toString()}');
    }
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw ServerException(message: 'No authenticated user found');
      }

      // First verify current password by trying to sign in
      try {
        await _supabaseClient.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword,
        );
      } catch (e) {
        throw ServerException(message: 'Current password is incorrect');
      }

      // Then update password
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to change password: ${e.toString()}');
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      final response = await _supabaseClient.auth.refreshSession();
      return response.session?.accessToken ?? '';
    } catch (e) {
      throw ServerException(message: 'Failed to refresh token: ${e.toString()}');
    }
  }

  /// Helper method to check if an email already exists in the system
  /// This uses multiple approaches to ensure we catch all cases
  Future<bool> _checkIfEmailExists(String email) async {
    try {
      // Method 1: Check in public.users table
      try {
        final existingUserQuery = await _supabaseClient
            .from('users')
            .select('email')
            .eq('email', email)
            .maybeSingle();

        if (existingUserQuery != null) {
          return true;
        }
      } catch (e) {
        // Continue to next method
      }

      // Method 2: Try to sign in with a dummy password
      try {
        await _supabaseClient.auth.signInWithPassword(
          email: email,
          password: 'Dummy_Password_123!',
        );
        return true;
      } catch (e) {
        String errorMsg = e.toString().toLowerCase();

        // If the error indicates the email exists but password is wrong
        if (errorMsg.contains('invalid login') ||
            errorMsg.contains('invalid email') ||
            errorMsg.contains('wrong password') ||
            errorMsg.contains('invalid credentials')) {
          return true;
        }

        // If the error indicates the email doesn't exist
        if (errorMsg.contains('user not found') ||
            errorMsg.contains('no user found') ||
            errorMsg.contains('no account')) {
          return false;
        }
      }

      // Method 3: Try to reset password for the email
      try {
        await _supabaseClient.auth.resetPasswordForEmail(email);
        return true;
      } catch (e) {
        String errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('user not found') ||
            errorMsg.contains('no user found') ||
            errorMsg.contains('no account')) {
          return false;
        }
      }

      // Default to assuming it doesn't exist
      return false;
    } catch (e) {
      // For any unexpected errors, default to false
      return false;
    }
  }

  // The _checkIfEmailExists method is defined above

  /// Helper method to create user profile in public.users and user_profiles tables
  Future<void> _createUserProfile(String userId, String email, String name, String? phone) async {
    try {
      // Create user in public.users table
      await _supabaseClient.from('users').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Also create a user_profile entry
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
      // Log the error but don't throw since we want to continue even if profile creation fails
      debugPrint('Error creating user profile: $e');
    }
  }
}