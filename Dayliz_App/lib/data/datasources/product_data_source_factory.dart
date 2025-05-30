import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../di/dependency_injection.dart' as di;
import 'product_remote_data_source.dart';
import 'product_supabase_data_source.dart';

/// Factory class to create the appropriate ProductRemoteDataSource based on configuration
class ProductDataSourceFactory {
  /// Get the active data source based on app configuration
  static ProductRemoteDataSource getActiveDataSource() {
    if (AppConfig.useFastAPI) {
      return getFastAPIDataSource();
    } else {
      return getSupabaseDataSource();
    }
  }

  /// Get the data source for a specific backend type
  static ProductRemoteDataSource getDataSource(AppConfig.BackendType type) {
    switch (type) {
      case AppConfig.BackendType.supabase:
        return getSupabaseDataSource();
      case AppConfig.BackendType.fastAPI:
        return getFastAPIDataSource();
    }
  }

  /// Get the Supabase data source
  static ProductRemoteDataSource getSupabaseDataSource() {
    // Get the Supabase client from GetIt if available, otherwise from Supabase.instance
    SupabaseClient supabaseClient;
    try {
      // Try to get from GetIt first
      supabaseClient = di.sl<SupabaseClient>();
      debugPrint('ProductDataSourceFactory: Got SupabaseClient from GetIt');
    } catch (e) {
      // Fallback to direct access
      supabaseClient = Supabase.instance.client;
      debugPrint('ProductDataSourceFactory: Got SupabaseClient from Supabase.instance');
    }

    return ProductSupabaseDataSource(
      supabaseClient: supabaseClient,
    );
  }

  /// Get the FastAPI data source
  static ProductRemoteDataSource getFastAPIDataSource() {
    // Use the existing HTTP implementation for FastAPI
    return ProductRemoteDataSourceImpl(
      client: di.sl<http.Client>(),
    );
  }
}
