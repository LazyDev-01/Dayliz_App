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
      debugPrint('AuthSupabaseDataSource: Registering user with email: $email, name: $name, phone: $phone');
      debugPrint('AuthSupabaseDataSource: Supabase client: $_supabaseClient');
      debugPrint('AuthSupabaseDataSource: Supabase auth: ${_supabaseClient.auth}');

      // IMPORTANT: For Supabase, we need to handle the registration differently
      // First, check if the user already exists
      try {
        final existingUser = await _supabaseClient.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (existingUser.user != null) {
          debugPrint('User already exists, returning existing user');
          return UserModel(
            id: existingUser.user!.id,
            email: email,
            name: existingUser.user!.userMetadata?['name'] ?? name,
            phone: existingUser.user!.userMetadata?['phone'] ?? phone,
            isEmailVerified: existingUser.user!.emailConfirmedAt != null,
          );
        }
      } catch (e) {
        // User doesn't exist, which is what we want for registration
        debugPrint('User does not exist, proceeding with registration');
      }

      debugPrint('About to call Supabase auth.signUp');
      debugPrint('Supabase client initialized: true');
      debugPrint('Supabase URL: ${dotenv.env['SUPABASE_URL']}');
      debugPrint('Password length: ${password.length}');
      debugPrint('Password has lowercase: ${RegExp(r'[a-z]').hasMatch(password)}');
      debugPrint('Password has uppercase: ${RegExp(r'[A-Z]').hasMatch(password)}');
      debugPrint('Password has number: ${RegExp(r'[0-9]').hasMatch(password)}');
      debugPrint('Password has special: ${RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)}');

      // Register the user with Supabase Auth
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      debugPrint('Supabase auth.signUp complete');
      debugPrint('Response details: Session=${response.session != null}, User=${response.user != null}');
      if (response.user != null) {
        debugPrint('User ID: ${response.user!.id}');
      }

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

      // Check for specific error messages
      if (e.message.contains('User already registered') || e.message.contains('already exists')) {
        throw ServerException(message: 'This email is already registered. Please use a different email or try logging in.');
      } else if (e.message.contains('Password should')) {
        throw ServerException(message: 'Password must contain at least one lowercase letter, one uppercase letter, one number, and one special character.');
      } else if (e.message.contains('invalid email')) {
        throw ServerException(message: 'Please enter a valid email address.');
      } else if (e.message.contains('unexpected_failure') || e.message.contains('Database error saving new user')) {
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

      // For any PostgrestException, check if we have a user in auth
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

      // For any error, check if we have a user in auth
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

  /// Helper method to create user profile in public.users and user_profiles tables
  Future<void> _createUserProfile(String userId, String email, String name, String? phone) async {
    try {
      debugPrint('Creating user profile in public.users table');
      await _supabaseClient.from('users').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('User profile created successfully');

      // Also create a user_profile entry
      debugPrint('Creating user_profile entry');
      await _supabaseClient.from('user_profiles').upsert({
        'id': userId,
        'user_id': userId,
        'full_name': name,
        'display_name': name,
        'avatar_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('User profile entry created successfully');
    } catch (e) {
      // Log the error but don't throw since we want to continue even if profile creation fails
      debugPrint('Error creating user profile: $e');
    }
  }
}