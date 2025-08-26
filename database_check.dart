import 'dart:io';
import 'dart:convert';

/// Standalone Dart script to check product distribution in Supabase database
///
/// Usage:
/// 1. Replace YOUR_SUPABASE_URL and YOUR_SUPABASE_ANON_KEY with actual values
/// 2. Run: dart database_check.dart
///
/// This script uses direct HTTP calls to Supabase REST API instead of the
/// supabase_flutter package to work as a standalone script.
void main() async {
  // Configuration - Replace with your actual Supabase credentials
  const supabaseUrl = 'YOUR_SUPABASE_URL';
  const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  final httpClient = HttpClient();

  print('🔍 Checking product distribution in database...\n');

  try {
    // Helper function to make Supabase REST API calls
    Future<Map<String, dynamic>> makeSupabaseRequest(String endpoint, {Map<String, String>? headers}) async {
      final request = await httpClient.getUrl(Uri.parse('$supabaseUrl/rest/v1/$endpoint'));
      request.headers.set('apikey', supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
      if (headers != null) {
        headers.forEach((key, value) => request.headers.set(key, value));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return {
          'data': json.decode(responseBody),
          'count': response.headers.value('content-range')?.split('/').last
        };
      } else {
        throw Exception('HTTP ${response.statusCode}: $responseBody');
      }
    }

    // 1. Get total product count
    final totalCountResponse = await makeSupabaseRequest(
      'products?select=id',
      headers: {'Prefer': 'count=exact'}
    );

    final totalProducts = int.tryParse(totalCountResponse['count'] ?? '0') ?? 0;
    print('📊 Total products in database: $totalProducts');

    // 2. Get product count by subcategory
    final subcategoryCountResponse = await makeSupabaseRequest(
      'products?select=subcategory_id,subcategories(name)&subcategory_id=not.is.null'
    );

    // Group by subcategory
    final subcategoryCounts = <String, int>{};
    final subcategoryNames = <String, String>{};

    final products = subcategoryCountResponse['data'] as List<dynamic>;
    for (final product in products) {
      final productMap = product as Map<String, dynamic>;
      final subcategoryId = productMap['subcategory_id'] as String;
      final subcategoryData = productMap['subcategories'] as Map<String, dynamic>?;
      final subcategoryName = subcategoryData?['name'] as String? ?? 'Unknown';

      subcategoryCounts[subcategoryId] = (subcategoryCounts[subcategoryId] ?? 0) + 1;
      subcategoryNames[subcategoryId] = subcategoryName;
    }

    print('\n📋 Product count by subcategory:');
    print('=' * 50);

    final sortedSubcategories = subcategoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedSubcategories) {
      final subcategoryId = entry.key;
      final count = entry.value;
      final name = subcategoryNames[subcategoryId] ?? 'Unknown';

      print('${name.padRight(30)} | $count products');

      if (count <= 20) {
        print('  ⚠️  This subcategory has ≤20 products');
      } else {
        print('  ✅ This subcategory has >20 products');
      }
    }

    // 3. Check for subcategories with more than 20 products
    final subcategoriesWithMany = sortedSubcategories
        .where((entry) => entry.value > 20)
        .length;

    print('\n📈 Summary:');
    print('Total subcategories: ${subcategoryCounts.length}');
    print('Subcategories with >20 products: $subcategoriesWithMany');
    print('Subcategories with ≤20 products: ${subcategoryCounts.length - subcategoriesWithMany}');

    // 4. Test actual query that the app uses
    print('\n🧪 Testing app query (limit 20):');
    final testResponse = await makeSupabaseRequest(
      'products?select=id,name,subcategory_id&limit=20'
    );

    final testProducts = testResponse['data'] as List<dynamic>;
    print('Query returned: ${testProducts.length} products');

  } catch (e) {
    print('❌ Error: $e');
  } finally {
    httpClient.close();
  }

  exit(0);
}