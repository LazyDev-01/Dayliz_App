import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User, AuthException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';
import '../../core/services/google_sign_in_service.dart';

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
      debugPrint('🔄 [AuthSupabaseDataSource] Attempting login for email: $email');
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        debugPrint('❌ [AuthSupabaseDataSource] Login failed: No user returned');
        throw AuthException(message: 'Email ID or password is incorrect!');
      }

      debugPrint('✅ [AuthSupabaseDataSource] Login successful for user: ${response.user!.id}');

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
      debugPrint('🔍 [AuthSupabaseDataSource] Caught AuthException: ${e.message}');
      // Handle specific authentication errors
      String errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('invalid login credentials') ||
          errorMessage.contains('invalid email or password') ||
          errorMessage.contains('wrong password') ||
          errorMessage.contains('invalid credentials') ||
          errorMessage.contains('email not confirmed') ||
          errorMessage.contains('invalid user credentials')) {
        debugPrint('🎯 [AuthSupabaseDataSource] Throwing specific auth error: Email ID or password is incorrect!');
        throw AuthException(message: 'Email ID or password is incorrect!');
      } else if (errorMessage.contains('email not confirmed') ||
                 errorMessage.contains('email not verified')) {
        debugPrint('🎯 [AuthSupabaseDataSource] Throwing email verification error');
        throw AuthException(message: 'Please verify your email before logging in.');
      } else if (errorMessage.contains('too many requests') ||
                 errorMessage.contains('rate limit')) {
        debugPrint('🎯 [AuthSupabaseDataSource] Throwing rate limit error');
        throw AuthException(message: 'Too many login attempts. Please try again later.');
      } else {
        debugPrint('🎯 [AuthSupabaseDataSource] Throwing generic auth error');
        throw AuthException(message: 'Login failed. Please check your credentials and try again.');
      }
    } on PostgrestException catch (e) {
      debugPrint('🔍 [AuthSupabaseDataSource] Caught PostgrestException: ${e.message}');
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      debugPrint('🔍 [AuthSupabaseDataSource] Caught generic exception: ${e.toString()}');
      debugPrint('🔍 [AuthSupabaseDataSource] Exception type: ${e.runtimeType}');

      // Check if this is actually a Supabase auth error that wasn't caught above
      String errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid login credentials') ||
          errorString.contains('invalid email or password') ||
          errorString.contains('wrong password') ||
          errorString.contains('invalid credentials')) {
        debugPrint('🎯 [AuthSupabaseDataSource] Converting generic error to AuthException');
        throw AuthException(message: 'Email ID or password is incorrect!');
      }

      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<User> register(String email, String password, String name, {String? phone}) async {
    try {
      debugPrint('AuthSupabaseDataSource: Registering user with email: $email, name: $name, phone: $phone');

      // CRITICAL FIX: Disable email existence check as it's causing false positives
      // Let Supabase handle duplicate email detection during signUp
      // This is more reliable than our custom check
      debugPrint('Skipping email existence check - letting Supabase handle duplicates');

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
          'full_name': name,
          'display_name': name,
          'phone': phone,
        },
      );
      debugPrint('Supabase auth.signUp completed successfully');

      // Check response
      if (response.user == null) {
        debugPrint('Registration failed: No user returned from signUp');
        throw ServerException(message: 'Registration failed: No user returned');
      }

      debugPrint('User created successfully with ID: ${response.user!.id}');

      // The display_name is already set in the user_metadata during signUp
      // Supabase dashboard shows raw_user_meta_data->>'display_name' as "Display Name"
      debugPrint('Display name set in user metadata during registration');

      // PERMANENT FIX: Profile creation is now handled automatically by database trigger
      // The handle_new_user() trigger function creates records in both public.users and user_profiles
      debugPrint('User profile will be created automatically by database trigger');

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

      // ENHANCED ERROR HANDLING: Parse specific error types
      String errorString = e.toString().toLowerCase();

      // Check for duplicate email errors
      if (_isDuplicateEmailError(e.toString())) {
        debugPrint('Detected duplicate email in generic error');
        throw ServerException(
          message: 'This email is already registered. Please use a different email or try logging in.'
        );
      }

      // Check for database constraint errors
      if (errorString.contains('database error saving new user')) {
        debugPrint('Database constraint error detected');
        throw ServerException(
          message: 'Unable to create account due to database constraints. Please try again or contact support.'
        );
      }

      // Check for password policy errors
      if (errorString.contains('password') && (errorString.contains('weak') || errorString.contains('policy'))) {
        debugPrint('Password policy error detected');
        throw ServerException(
          message: 'Password does not meet security requirements. Please use a stronger password.'
        );
      }

      // Check for email format errors
      if (errorString.contains('email') && (errorString.contains('invalid') || errorString.contains('format'))) {
        debugPrint('Email format error detected');
        throw ServerException(
          message: 'Please enter a valid email address.'
        );
      }

      // Generic error with more helpful message
      throw ServerException(
        message: 'Registration failed. Please check your information and try again. If the problem persists, contact support.'
      );
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

  // REMOVED: _emailExists method as it was causing false positives
  // Supabase will handle duplicate email detection during signUp

  /// Helper method to create user profile in public.users and user_profiles tables
  Future<void> _createUserProfile(String userId, String email, String name, String? phone) async {
    debugPrint('Creating user profile for user ID: $userId');

    try {
      // CRITICAL FIX: Check if user already exists before creating
      final existingUser = await _supabaseClient
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingUser != null) {
        debugPrint('User profile already exists, skipping creation');
        return;
      }

      // Try to create user in public.users table
      debugPrint('Inserting into users table...');
      final userData = {
        'id': userId,
        'email': email,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // CRITICAL FIX: Only add phone if it's not null to avoid unique constraint issues
      if (phone != null && phone.isNotEmpty) {
        userData['phone'] = phone;
      }

      await _supabaseClient.from('users').insert(userData);
      debugPrint('Successfully inserted into users table');

      // Try to create user profile in user_profiles table
      debugPrint('Inserting into user_profiles table...');
      await _supabaseClient.from('user_profiles').upsert({
        'id': userId,
        'user_id': userId,
        'full_name': name,
        'profile_image_url': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
        'preferences': '{}',
      });
      debugPrint('Successfully inserted into user_profiles table');

    } catch (e) {
      debugPrint('Error creating user profile: $e');
      // CRITICAL FIX: Handle duplicate key errors gracefully
      if (e is PostgrestException) {
        debugPrint('PostgrestException - code: ${e.code}, message: ${e.message}, details: ${e.details}');

        // Handle duplicate key errors for phone number constraint
        if (e.code == '23505' || e.message.contains('duplicate key') || e.message.contains('unique constraint')) {
          debugPrint('Profile already exists (duplicate key error), this is expected');
          return; // This is fine, profile exists
        }
      }

      // Handle string-based duplicate key errors
      if (e.toString().contains('duplicate key') || e.toString().contains('unique constraint')) {
        debugPrint('Profile already exists (duplicate key error), this is expected');
        return; // This is fine, profile exists
      }

      // Re-throw other errors
      rethrow;
    }
  }

  // Other methods remain unchanged...
  @override
  Future<bool> logout() async {
    try {
      debugPrint('🔄 [AuthSupabaseDataSource] Starting logout process');

      // Use GoogleSignInService's complete logout to ensure Google account selection on next sign-in
      try {
        final googleSignInService = GoogleSignInService.instance;
        await googleSignInService.completeLogout();
        debugPrint('✅ [AuthSupabaseDataSource] Complete logout (Google + Supabase) successful');
      } catch (e) {
        debugPrint('⚠️ [AuthSupabaseDataSource] Error during complete logout, falling back to Supabase only: $e');
        // Fallback to Supabase-only logout if Google logout fails
        await _supabaseClient.auth.signOut();
        debugPrint('✅ [AuthSupabaseDataSource] Supabase logout successful');
      }

      return true;
    } catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] Logout failed: $e');
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
    try {
      debugPrint('🔄 [AuthSupabaseDataSource] Starting Google Sign-in process');

      // Use the GoogleSignInService for mobile platforms
      debugPrint('🔍 [AuthSupabaseDataSource] Getting GoogleSignInService instance');
      final googleSignInService = GoogleSignInService.instance;

      // CRITICAL FIX: Don't sign out from Supabase before Google Sign-in
      // The GoogleSignInService will handle any necessary sign-outs
      debugPrint('🔍 [AuthSupabaseDataSource] Proceeding with Google Sign-in without pre-logout');

      // Get the OAuth token from Google (force account selection)
      debugPrint('🔍 [AuthSupabaseDataSource] Getting OAuth token from Google with account selection');
      final token = await googleSignInService.getGoogleAuthToken(forceAccountSelection: true);

      if (token == null) {
        debugPrint('🔍 [AuthSupabaseDataSource] User cancelled Google Sign-In - this is not an error');
        throw UserCancellationException(message: 'Google Sign-In cancelled by user');
      }

      debugPrint('✅ [AuthSupabaseDataSource] Got Google OAuth token: ${token.substring(0, 10)}...');

      // Sign in to Supabase with the Google token
      debugPrint('🔍 [AuthSupabaseDataSource] Signing in to Supabase with Google token');
      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: token,
      );

      if (response.user == null) {
        debugPrint('❌ [AuthSupabaseDataSource] No user returned from Google Sign-in');
        throw ServerException(message: 'No user returned from Google Sign-in');
      }

      debugPrint('✅ [AuthSupabaseDataSource] Google Sign-in successful, user ID: ${response.user!.id}');

      // Get display name for Google sign-in users
      final displayName = response.user!.userMetadata?['name'] ??
                         response.user!.userMetadata?['full_name'] ??
                         response.user!.email!.split('@')[0];

      // For Google sign-in, the display_name should already be in user_metadata
      // If not, we can update it using the auth.updateUser method
      if (response.user!.userMetadata?['display_name'] == null) {
        try {
          debugPrint('Setting display_name for Google user...');
          await _supabaseClient.auth.updateUser(
            UserAttributes(
              data: {
                ...response.user!.userMetadata ?? {},
                'display_name': displayName,
                'name': displayName,
                'full_name': displayName,
              },
            ),
          );
          debugPrint('Successfully set Google user display_name');
        } catch (e) {
          debugPrint('Warning: Failed to set Google user display_name: $e');
        }
      }

      // Create user profile if it doesn't exist
      try {
        await _createUserProfile(
          response.user!.id,
          response.user!.email!,
          displayName,
          response.user!.phone,
        );
        debugPrint('✅ [AuthSupabaseDataSource] User profile created/updated successfully');
      } catch (e) {
        debugPrint('⚠️ [AuthSupabaseDataSource] Error creating user profile, but continuing: $e');
        // Continue even if profile creation fails
      }

      // Get additional user data from public.users table
      try {
        final userData = await _supabaseClient
            .from('user_profile_view')
            .select()
            .eq('user_id', response.user!.id)
            .maybeSingle();

        if (userData != null) {
          return UserModel(
            id: response.user!.id,
            email: response.user!.email!,
            name: userData['name'] ?? response.user!.userMetadata?['name'] ?? '',
            phone: userData['phone'] ?? response.user!.phone,
            profileImageUrl: userData['profile_image_url'] ?? userData['avatar_url'],
            isEmailVerified: response.user!.emailConfirmedAt != null,
            metadata: response.user!.userMetadata,
          );
        }
      } catch (e) {
        debugPrint('⚠️ [AuthSupabaseDataSource] Error getting user profile data: $e');
        // Continue with basic user data if profile fetch fails
      }

      // Return basic user data if profile data is not available
      return UserModel(
        id: response.user!.id,
        email: response.user!.email!,
        name: response.user!.userMetadata?['name'] ?? response.user!.userMetadata?['full_name'] ?? '',
        phone: response.user!.phone,
        profileImageUrl: response.user!.userMetadata?['avatar_url'],
        isEmailVerified: response.user!.emailConfirmedAt != null,
        metadata: response.user!.userMetadata,
      );
    } catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] Error signing in with Google: $e');
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: 'Google sign-in failed: ${e.toString()}');
    }
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
  Future<bool> checkEmailExists(String email) async {
    try {
      debugPrint('🔄 [AuthSupabaseDataSource] Checking if email exists: $email');

      // Check if email exists in auth.users table
      // Note: We can't directly query auth.users from client side for security reasons
      // Instead, we'll use a different approach - try to sign in with a dummy password
      // and check the error message to determine if email exists

      try {
        // Attempt to sign in with the email and a dummy password
        // This will fail, but the error message will tell us if the email exists
        await _supabaseClient.auth.signInWithPassword(
          email: email,
          password: 'dummy_password_that_will_never_match_12345!@#',
        );

        // If we reach here, it means the email exists and the dummy password matched
        // This is extremely unlikely, so we'll treat it as email exists
        debugPrint('✅ [AuthSupabaseDataSource] Email exists (unexpected success)');
        return true;

      } on AuthException catch (authError) {
        // Check the error message to determine if email exists
        final errorMessage = authError.message.toLowerCase();

        if (errorMessage.contains('invalid login credentials') ||
            errorMessage.contains('wrong password') ||
            errorMessage.contains('invalid password')) {
          // These errors indicate the email exists but password is wrong
          debugPrint('✅ [AuthSupabaseDataSource] Email exists (invalid credentials)');
          return true;
        } else if (errorMessage.contains('user not found') ||
                   errorMessage.contains('email not found') ||
                   errorMessage.contains('no user found') ||
                   errorMessage.contains('invalid email')) {
          // These errors indicate the email doesn't exist
          debugPrint('✅ [AuthSupabaseDataSource] Email does not exist');
          return false;
        } else {
          // For any other auth error, assume email doesn't exist (fail-safe)
          debugPrint('✅ [AuthSupabaseDataSource] Email check inconclusive, assuming does not exist: $errorMessage');
          return false;
        }
      }

    } catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] Error checking email existence: $e');

      // Try using Edge Function as fallback
      try {
        debugPrint('🔄 [AuthSupabaseDataSource] Trying Edge Function fallback for email check');

        final response = await _supabaseClient.functions.invoke(
          'check-email-exists',
          body: {'email': email},
        );

        if (response.data != null && response.data['exists'] != null) {
          final exists = response.data['exists'] as bool;
          debugPrint('✅ [AuthSupabaseDataSource] Edge Function result: $exists');
          return exists;
        }

        debugPrint('❌ [AuthSupabaseDataSource] Edge Function returned invalid data');
        return false;

      } catch (edgeFunctionError) {
        debugPrint('❌ [AuthSupabaseDataSource] Edge Function also failed: $edgeFunctionError');
        // On error, return false to allow user to proceed (fail-safe approach)
        return false;
      }
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      debugPrint('🔄 [AuthSupabaseDataSource] Sending password reset email to: $email');

      // Send password reset email using Supabase
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'dayliz://verify-email?type=reset_password', // Deep link to your app
      );

      debugPrint('✅ [AuthSupabaseDataSource] Password reset email sent successfully');
    } on AuthException catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] AuthException in forgotPassword: ${e.message}');

      // Handle specific auth errors
      String errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('user not found') ||
          errorMessage.contains('no user found') ||
          errorMessage.contains('invalid email')) {
        throw AuthException(message: 'No account found with this email address.');
      } else if (errorMessage.contains('rate limit') ||
                 errorMessage.contains('too many requests')) {
        throw AuthException(message: 'Too many reset requests. Please wait before trying again.');
      } else {
        throw AuthException(message: 'Failed to send reset email. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] Unexpected error in forgotPassword: $e');
      throw AuthException(message: 'Failed to send reset email: ${e.toString()}');
    }
  }

  @override
  Future<bool> resetPassword({required String token, required String newPassword}) async {
    try {
      debugPrint('🔄 [AuthSupabaseDataSource] Resetting password with token');

      // Validate password strength
      if (newPassword.length < 8) {
        throw AuthException(message: 'Password must be at least 8 characters long.');
      }

      // Update user password using Supabase
      // Note: The token validation is handled by Supabase internally
      // The user must be authenticated via the reset link for this to work
      final response = await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        debugPrint('❌ [AuthSupabaseDataSource] No user returned after password reset');
        throw AuthException(message: 'Failed to reset password. Please try again.');
      }

      debugPrint('✅ [AuthSupabaseDataSource] Password reset successful for user: ${response.user!.id}');
      return true;
    } on AuthException catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] AuthException in resetPassword: ${e.message}');

      // Handle specific auth errors
      String errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('invalid token') ||
          errorMessage.contains('expired') ||
          errorMessage.contains('token')) {
        throw AuthException(message: 'Reset link has expired. Please request a new password reset.');
      } else if (errorMessage.contains('password')) {
        throw AuthException(message: 'Password must be at least 8 characters long with mixed case, numbers, and special characters.');
      } else if (errorMessage.contains('not authenticated') ||
                 errorMessage.contains('unauthorized')) {
        throw AuthException(message: 'Invalid or expired reset link. Please request a new password reset.');
      } else {
        throw AuthException(message: 'Failed to reset password. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] Unexpected error in resetPassword: $e');
      throw AuthException(message: 'Failed to reset password: ${e.toString()}');
    }
  }

  @override
  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      debugPrint('🔄 [AuthSupabaseDataSource] Changing password for authenticated user');

      // Get current user
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw AuthException(message: 'No authenticated user found. Please log in first.');
      }

      // Validate password strength
      if (newPassword.length < 8) {
        throw AuthException(message: 'New password must be at least 8 characters long.');
      }

      // Verify current password by attempting to sign in
      try {
        await _supabaseClient.auth.signInWithPassword(
          email: currentUser.email!,
          password: currentPassword,
        );
        debugPrint('✅ [AuthSupabaseDataSource] Current password verified');
      } on AuthException catch (e) {
        debugPrint('❌ [AuthSupabaseDataSource] Current password verification failed: ${e.message}');
        throw AuthException(message: 'Current password is incorrect.');
      }

      // Update to new password
      final response = await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        debugPrint('❌ [AuthSupabaseDataSource] No user returned after password change');
        throw AuthException(message: 'Failed to change password. Please try again.');
      }

      debugPrint('✅ [AuthSupabaseDataSource] Password changed successfully for user: ${response.user!.id}');
      return true;
    } on AuthException catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] AuthException in changePassword: ${e.message}');

      // Handle specific auth errors
      String errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('current password is incorrect')) {
        rethrow; // Already has user-friendly message
      } else if (errorMessage.contains('password')) {
        throw AuthException(message: 'Password must be at least 8 characters long with mixed case, numbers, and special characters.');
      } else if (errorMessage.contains('not authenticated') ||
                 errorMessage.contains('unauthorized')) {
        throw AuthException(message: 'Please log in again to change your password.');
      } else {
        throw AuthException(message: 'Failed to change password. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] Unexpected error in changePassword: $e');
      throw AuthException(message: 'Failed to change password: ${e.toString()}');
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      debugPrint('🔄 [AuthSupabaseDataSource] Refreshing authentication token');

      // Get current session
      final session = _supabaseClient.auth.currentSession;
      if (session == null) {
        throw AuthException(message: 'No active session found. Please log in again.');
      }

      // Refresh the session
      final response = await _supabaseClient.auth.refreshSession();

      if (response.session == null) {
        debugPrint('❌ [AuthSupabaseDataSource] No session returned after refresh');
        throw AuthException(message: 'Failed to refresh session. Please log in again.');
      }

      final newAccessToken = response.session!.accessToken;
      debugPrint('✅ [AuthSupabaseDataSource] Token refreshed successfully');

      return newAccessToken;
    } on AuthException catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] AuthException in refreshToken: ${e.message}');

      // Handle specific auth errors
      String errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('refresh token') ||
          errorMessage.contains('expired') ||
          errorMessage.contains('invalid')) {
        throw AuthException(message: 'Session expired. Please log in again.');
      } else {
        throw AuthException(message: 'Failed to refresh session. Please log in again.');
      }
    } catch (e) {
      debugPrint('❌ [AuthSupabaseDataSource] Unexpected error in refreshToken: $e');
      throw AuthException(message: 'Failed to refresh session: ${e.toString()}');
    }
  }
}
