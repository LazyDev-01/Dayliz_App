import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart_remote_data_source.dart';
import 'cart_supabase_data_source.dart';
import '../../core/config/app_config.dart';
import '../../di/dependency_injection.dart' as di;

/// Enum to represent the different backend types
enum BackendType {
  supabase,
  fastAPI,
}

/// Factory class to create the appropriate CartRemoteDataSource based on configuration
class CartDataSourceFactory {
  /// Get the active data source based on app configuration
  static CartRemoteDataSource getActiveDataSource() {
    if (AppConfig.useFastAPI) {
      return getFastAPIDataSource();
    } else {
      return getSupabaseDataSource();
    }
  }

  /// Get the data source for a specific backend type
  static CartRemoteDataSource getDataSource(BackendType type) {
    switch (type) {
      case BackendType.supabase:
        return getSupabaseDataSource();
      case BackendType.fastAPI:
        return getFastAPIDataSource();
    }
  }

  /// Get the Supabase data source
  static CartRemoteDataSource getSupabaseDataSource() {
    // Get the Supabase client from GetIt if available, otherwise from Supabase.instance
    SupabaseClient supabaseClient;
    try {
      // Try to get from GetIt first
      supabaseClient = di.sl<SupabaseClient>();
      debugPrint('CartDataSourceFactory: Got SupabaseClient from GetIt');
    } catch (e) {
      // Fallback to direct access
      supabaseClient = Supabase.instance.client;
      debugPrint('CartDataSourceFactory: Got SupabaseClient from Supabase.instance');
    }

    return CartSupabaseDataSource(
      supabaseClient: supabaseClient,
    );
  }

  /// Get the FastAPI data source
  static CartRemoteDataSource getFastAPIDataSource() {
    // Use the existing HTTP implementation for FastAPI
    return CartRemoteDataSourceImpl(
      client: di.sl<http.Client>(),
    );
  }
}