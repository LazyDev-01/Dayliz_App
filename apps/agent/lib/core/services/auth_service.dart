import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_types/shared_types.dart';

/// Professional AuthService for Dayliz Agent App
/// Handles email/phone-based authentication for approved agents
/// Note: Agents are created by the Dayliz team, not through registration
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is currently authenticated
  bool get isAuthenticated => currentUser != null;
  
  /// Agent Login with Email/Phone and Password
  /// Returns AgentModel on success, throws exception on failure
  Future<AgentModel> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      // Determine if input is email or phone
      final isEmail = emailOrPhone.contains('@');
      final isPhone = RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(emailOrPhone);

      if (!isEmail && !isPhone) {
        throw AuthException('Please enter a valid email address or phone number');
      }

      String authEmail;

      if (isEmail) {
        // Use email directly for authentication
        authEmail = emailOrPhone;
      } else {
        // For phone number, find the associated email from agents table
        final agentLookup = await _supabase
            .from('agents')
            .select('user_id')
            .eq('phone', emailOrPhone)
            .eq('status', 'active')
            .single();

        if (agentLookup.isEmpty) {
          throw AuthException('No active agent found with this phone number');
        }

        // Get the email from auth.users table using RPC function
        final userLookup = await _supabase
            .rpc('get_user_email', params: {'user_id': agentLookup['user_id']});

        if (userLookup == null || userLookup.isEmpty) {
          throw AuthException('Unable to find email for this phone number');
        }

        authEmail = userLookup as String;
      }

      // Authenticate with Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: authEmail,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Login failed. Please check your credentials.');
      }

      // Fetch agent data from our agents table
      final agentData = await _supabase
          .from('agents')
          .select()
          .eq('user_id', response.user!.id)
          .single();
      
      // Convert to AgentModel
      final agent = AgentModel.fromJson(agentData);
      
      // Check if agent is active
      if (agent.status == AgentStatus.suspended) {
        throw AuthException('Your account has been suspended. Please contact support.');
      }

      if (agent.status == AgentStatus.inactive) {
        throw AuthException('Your account is inactive. Please contact support.');
      }
      
      return agent;
      
    } on AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw AuthException('Agent not found. Please check your credentials.');
      }
      throw AuthException('Database error: ${e.message}');
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }
  
  /// Submit agent application (no account creation)
  /// Data goes to pending_agents table for team review
  Future<String> submitApplication({
    required String fullName,
    required String phone,
    required String email,
    required String workType,
    required int age,
    required String gender,
    required String address,
    required String vehicleType,
  }) async {
    try {
      // Insert application into pending_agents table
      await _supabase.from('pending_agents').insert({
        'full_name': fullName,
        'phone': phone,
        'email': email.isNotEmpty ? email : null,
        'work_type': workType,
        'age': age,
        'gender': gender,
        'address': address,
        'vehicle_type': vehicleType,
        'application_status': 'pending',
        'applied_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return 'Application submitted successfully! Our team will review your application and contact you within 24-48 hours.';

    } on PostgrestException catch (e) {
      throw AuthException('Application submission failed: ${e.message}');
    } catch (e) {
      throw AuthException('Application submission failed: ${e.toString()}');
    }
  }
  
  /// Get current agent data
  Future<AgentModel?> getCurrentAgent() async {
    try {
      final user = currentUser;
      if (user == null) return null;
      
      final agentData = await _supabase
          .from('agents')
          .select()
          .eq('user_id', user.id)
          .single();
      
      return AgentModel.fromJson(agentData);
      
    } catch (e) {
      return null;
    }
  }
  
  /// Logout current user
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Logout failed: ${e.toString()}');
    }
  }
  
  // Removed unused helper methods - agents are created by team, not through app
  
  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  /// Reset password (contact support for password reset)
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }
  
  /// Update agent password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AuthException('Password update failed: ${e.toString()}');
    }
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => message;
}
