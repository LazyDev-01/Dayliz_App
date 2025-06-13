import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final supabase = Supabase.instance.client;

  print('🔍 Checking product distribution in database...\n');

  try {
    // 1. Get total product count
    final totalCountResponse = await supabase
        .from('products')
        .select('id', const FetchOptions(count: CountOption.exact));

    final totalProducts = totalCountResponse.count ?? 0;
    print('📊 Total products in database: $totalProducts');

    // 2. Get product count by subcategory
    final subcategoryCountResponse = await supabase
        .from('products')
        .select('subcategory_id, subcategories(name)')
        .not('subcategory_id', 'is', null);

    // Group by subcategory
    final subcategoryCounts = <String, int>{};
    final subcategoryNames = <String, String>{};

    for (final product in subcategoryCountResponse) {
      final subcategoryId = product['subcategory_id'] as String;
      final subcategoryName = product['subcategories']?['name'] as String? ?? 'Unknown';

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
    final testResponse = await supabase
        .from('products')
        .select('id, name, subcategory_id')
        .limit(20);

    print('Query returned: ${testResponse.length} products');

  } catch (e) {
    print('❌ Error: $e');
  }

  exit(0);
}