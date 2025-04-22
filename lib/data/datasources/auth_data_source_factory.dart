import 'package:http/http.dart' as http;

import 'auth_data_source.dart';
import 'auth_remote_data_source.dart';
import '../../core/config/app_config.dart';
import '../../di/dependency_injection.dart' as di;

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
    // Use manual instantiation with dependencies from DI container
    return AuthRemoteDataSourceImpl(client: di.sl<http.Client>());
  }

  /// Get the FastAPI data source
  static AuthDataSource getFastAPIDataSource() {
    // For now, return the same implementation since FastAPI version isn't ready
    return AuthRemoteDataSourceImpl(client: di.sl<http.Client>());
  }
} 