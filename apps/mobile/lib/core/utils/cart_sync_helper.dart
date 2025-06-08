import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../di/dependency_injection.dart' as di;

/// Helper class for cart synchronization and authentication debugging
class CartSyncHelper {
  static final CartSyncHelper _instance = CartSyncHelper._internal();
  static CartSyncHelper get instance => _instance;
  CartSyncHelper._internal();

  /// Check authentication status with detailed logging
  static Future<bool> checkAuthenticationStatus() async {
    try {
      debugPrint('🔐 CART SYNC: Checking authentication status...');
      
      // Get Supabase client
      final supabaseClient = di.sl<SupabaseClient>();
      final user = supabaseClient.auth.currentUser;
      final session = supabaseClient.auth.currentSession;
      
      debugPrint('🔐 CART SYNC: User ID: ${user?.id ?? 'null'}');
      debugPrint('🔐 CART SYNC: User Email: ${user?.email ?? 'null'}');
      debugPrint('🔐 CART SYNC: Session exists: ${session != null}');
      
      if (session != null) {
        debugPrint('🔐 CART SYNC: Session expires at: ${session.expiresAt}');
        final now = DateTime.now().millisecondsSinceEpoch / 1000;
        final isExpired = session.expiresAt != null && session.expiresAt! <= now;
        debugPrint('🔐 CART SYNC: Session expired: $isExpired');
        
        if (isExpired) {
          debugPrint('🔐 CART SYNC: Attempting to refresh session...');
          try {
            await supabaseClient.auth.refreshSession();
            debugPrint('🔐 CART SYNC: ✅ Session refreshed successfully');
            return true;
          } catch (e) {
            debugPrint('🔐 CART SYNC: ❌ Session refresh failed: $e');
            return false;
          }
        }
      }
      
      final isAuthenticated = user != null && session != null;
      debugPrint('🔐 CART SYNC: Authentication status: ${isAuthenticated ? 'AUTHENTICATED' : 'NOT AUTHENTICATED'}');
      
      return isAuthenticated;
    } catch (e) {
      debugPrint('🔐 CART SYNC: ❌ Error checking authentication: $e');
      return false;
    }
  }

  /// Test database connectivity
  static Future<bool> testDatabaseConnectivity() async {
    try {
      debugPrint('🔗 CART SYNC: Testing database connectivity...');
      
      final supabaseClient = di.sl<SupabaseClient>();
      
      // Simple query to test connection
      final response = await supabaseClient
          .from('products')
          .select('id')
          .limit(1);
      
      debugPrint('🔗 CART SYNC: ✅ Database connection successful');
      debugPrint('🔗 CART SYNC: Response: ${response.length} records');
      return true;
    } catch (e) {
      debugPrint('🔗 CART SYNC: ❌ Database connection failed: $e');
      return false;
    }
  }

  /// Test cart table access
  static Future<bool> testCartTableAccess() async {
    try {
      debugPrint('🛒 CART SYNC: Testing cart table access...');
      
      final supabaseClient = di.sl<SupabaseClient>();
      final user = supabaseClient.auth.currentUser;
      
      if (user == null) {
        debugPrint('🛒 CART SYNC: ❌ No authenticated user for cart table test');
        return false;
      }
      
      // Try to query cart items for current user
      final response = await supabaseClient
          .from('cart_items')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      
      debugPrint('🛒 CART SYNC: ✅ Cart table access successful');
      debugPrint('🛒 CART SYNC: User has ${response.length} cart items');
      return true;
    } catch (e) {
      debugPrint('🛒 CART SYNC: ❌ Cart table access failed: $e');
      return false;
    }
  }

  /// Run comprehensive cart sync diagnostics
  static Future<Map<String, bool>> runDiagnostics() async {
    debugPrint('🔍 CART SYNC: Running comprehensive diagnostics...');
    
    final results = <String, bool>{};
    
    // Test authentication
    results['authentication'] = await checkAuthenticationStatus();
    
    // Test database connectivity
    results['database_connectivity'] = await testDatabaseConnectivity();
    
    // Test cart table access (only if authenticated)
    if (results['authentication'] == true) {
      results['cart_table_access'] = await testCartTableAccess();
    } else {
      results['cart_table_access'] = false;
    }
    
    // Print summary
    debugPrint('🔍 CART SYNC: Diagnostics Summary:');
    results.forEach((test, passed) {
      debugPrint('🔍 CART SYNC: $test: ${passed ? '✅ PASS' : '❌ FAIL'}');
    });
    
    final allPassed = results.values.every((result) => result);
    debugPrint('🔍 CART SYNC: Overall Status: ${allPassed ? '✅ ALL SYSTEMS GO' : '❌ ISSUES DETECTED'}');
    
    return results;
  }

  /// Get authentication recommendations
  static List<String> getAuthenticationRecommendations(Map<String, bool> diagnostics) {
    final recommendations = <String>[];
    
    if (diagnostics['authentication'] != true) {
      recommendations.add('User needs to login to enable database sync');
      recommendations.add('Cart will work locally but won\'t sync across devices');
    }
    
    if (diagnostics['database_connectivity'] != true) {
      recommendations.add('Check internet connection');
      recommendations.add('Verify Supabase configuration');
    }
    
    if (diagnostics['cart_table_access'] != true && diagnostics['authentication'] == true) {
      recommendations.add('Check cart_items table permissions');
      recommendations.add('Verify RLS policies are configured correctly');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('All systems working correctly!');
      recommendations.add('Cart will sync with database');
    }
    
    return recommendations;
  }
}
