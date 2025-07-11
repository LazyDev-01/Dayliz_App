import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_types/shared_types.dart';

/// Authentication service for agent app
/// Handles simple ID + password authentication
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _agentIdKey = 'agent_id';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Current authenticated agent
  AgentModel? _currentAgent;
  AgentModel? get currentAgent => _currentAgent;

  /// Check if agent is currently logged in
  bool get isLoggedIn => _currentAgent != null;

  /// Initialize the auth service and check for existing session
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final agentId = prefs.getString(_agentIdKey);

    if (isLoggedIn && agentId != null) {
      try {
        // Try to restore session by fetching agent data
        await _fetchAgentData(agentId);
      } catch (e) {
        // If restoration fails, clear stored data
        await logout();
      }
    }
  }

  /// Login with agent ID and password
  Future<AuthResult> login({
    required String agentId,
    required String password,
  }) async {
    try {
      // First, get the agent record to find the associated user_id
      final agentResponse = await _supabase
          .from('agents')
          .select('*, auth.users!inner(email)')
          .eq('agent_id', agentId)
          .eq('status', 'active')
          .single();

      if (agentResponse.isEmpty) {
        return AuthResult.failure('Agent ID not found or inactive');
      }

      final agentData = agentResponse as Map<String, dynamic>;
      final userEmail = agentData['users']['email'] as String;

      // Authenticate with Supabase using email and password
      final authResponse = await _supabase.auth.signInWithPassword(
        email: userEmail,
        password: password,
      );

      if (authResponse.user == null) {
        return AuthResult.failure('Invalid credentials');
      }

      // Create agent model from response
      _currentAgent = AgentModel.fromJson(agentData);

      // Store login state
      await _storeLoginState(agentId);

      return AuthResult.success(_currentAgent!);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Logout the current agent
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Continue with logout even if Supabase signout fails
    }

    _currentAgent = null;
    await _clearLoginState();
  }

  /// Fetch agent data by agent ID
  Future<void> _fetchAgentData(String agentId) async {
    final response = await _supabase
        .from('agents')
        .select()
        .eq('agent_id', agentId)
        .single();

    _currentAgent = AgentModel.fromJson(response);
  }

  /// Store login state in local storage
  Future<void> _storeLoginState(String agentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_agentIdKey, agentId);
  }

  /// Clear login state from local storage
  Future<void> _clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_agentIdKey);
  }

  /// Update agent status (for shift management)
  Future<bool> updateAgentStatus(AgentStatus status) async {
    if (_currentAgent == null) return false;

    try {
      await _supabase
          .from('agents')
          .update({'status': status.name, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', _currentAgent!.id);

      _currentAgent = _currentAgent!.copyWith(status: status);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get agent profile data
  Future<AgentModel?> getAgentProfile() async {
    if (_currentAgent == null) return null;

    try {
      final response = await _supabase
          .from('agents')
          .select()
          .eq('id', _currentAgent!.id)
          .single();

      _currentAgent = AgentModel.fromJson(response);
      return _currentAgent;
    } catch (e) {
      return null;
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final AgentModel? agent;

  AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.agent,
  });

  factory AuthResult.success(AgentModel agent) {
    return AuthResult._(
      isSuccess: true,
      agent: agent,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}