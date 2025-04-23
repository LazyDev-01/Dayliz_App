import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_data_source.dart';
import 'auth_supabase_data_source.dart';
import '../../core/config/app_config.dart';
import '../../di/dependency_injection.dart' as di;
import '../../services/auth_service.dart' as auth_service;

/// Enum to represent the different backend types
enum BackendType {
  supabase,
  fastAPI,
}

/// Factory class to create the appropriate AuthDataSource based on configuration
class AuthDataSourceFactory {
  /// Get the active data source based on app configuration
  static AuthDataSource getActiveDataSource() {
    if (AppConfig.useFastAPI) {
      return getFastAPIDataSource();
    } else {
      return getSupabaseDataSource();
    }
  }

  /// Get the data source for a specific backend type
  static AuthDataSource getDataSource(BackendType type) {
    switch (type) {
      case BackendType.supabase:
        return getSupabaseDataSource();
      case BackendType.fastAPI:
        return getFastAPIDataSource();
    }
  }

  /// Get the Supabase data source
  static AuthDataSource getSupabaseDataSource() {
    // Get the Supabase client from the AuthService
    final authService = di.sl<auth_service.AuthService>();

    // Make sure AuthService is initialized
    if (!authService.isInitialized) {
      authService.initialize();
    }

    // Get the Supabase client
    final supabaseClient = Supabase.instance.client;

    // Return the Supabase-specific implementation
    return AuthSupabaseDataSource(supabaseClient: supabaseClient);
  }

  /// Get the FastAPI data source
  static AuthDataSource getFastAPIDataSource() {
    // For now, return the Supabase implementation since FastAPI version isn't ready
    return getSupabaseDataSource();
  }
}