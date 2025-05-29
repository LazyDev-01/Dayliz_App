import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration result for Supabase
class SupabaseConfig {
  final bool isConfigured;
  final String? url;
  final String? anonKey;

  SupabaseConfig({
    required this.isConfigured,
    this.url,
    this.anonKey,
  });
}

/// Utility class for checking Supabase configuration
class SupabaseConfigChecker {
  /// Check if Supabase is properly configured
  static Future<SupabaseConfig> checkSupabaseConfig() async {
    try {
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      final isConfigured = url != null && url.isNotEmpty && 
                          anonKey != null && anonKey.isNotEmpty;

      return SupabaseConfig(
        isConfigured: isConfigured,
        url: url,
        anonKey: anonKey,
      );
    } catch (e) {
      debugPrint('Error checking Supabase config: $e');
      return SupabaseConfig(isConfigured: false);
    }
  }
}
