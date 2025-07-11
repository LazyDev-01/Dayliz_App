import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/category.dart';

/// Main category provider that directly fetches categories from Supabase
/// This is the consolidated provider for all category operations
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    debugPrint('🏷️ PROVIDER: Fetching categories with display_order...');
    // Fetch categories with subcategories from Supabase
    // Use database display_order for proper sorting (explicitly ascending)
    final response = await Supabase.instance.client
        .from('categories')
        .select('*, subcategories(*)')
        .order('display_order', ascending: true); // Explicitly order ascending by display_order

    debugPrint('🏷️ PROVIDER: Raw response: $response');
    // Convert to Category entities (already sorted by display_order from database)
    final categories = response.map((data) => _mapToCategory(data)).toList();

    debugPrint('🏷️ PROVIDER: Final categories order: ${categories.map((c) => '${c.name}(${c.displayOrder})').toList()}');

    return categories;
  } catch (e) {
    throw Exception('Failed to load categories: ${e.toString()}');
  }
});



/// Map Supabase data to Category entity
Category _mapToCategory(Map<String, dynamic> data) {
  // Parse subcategories if available
  List<SubCategory>? subcategories;
  if (data['subcategories'] != null) {
    final subcategoriesData = data['subcategories'] as List<dynamic>;
    subcategories = subcategoriesData
        .map((subData) => _mapToSubCategory(subData))
        .toList();

    // Sort subcategories by display order
    subcategories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  return Category(
    id: data['id'] ?? '',
    name: data['name'] ?? '',
    icon: _getIconFromString(data['icon_name']),
    themeColor: _getColorFromHex(data['theme_color']),
    imageUrl: data['image_url'],
    displayOrder: data['display_order'] ?? 0,
    subCategories: subcategories,
  );
}

/// Map Supabase data to SubCategory entity
SubCategory _mapToSubCategory(Map<String, dynamic> data) {
  return SubCategory(
    id: data['id'] ?? '',
    name: data['name'] ?? '',
    parentId: data['category_id'] ?? '',
    imageUrl: data['image_url'],
    displayOrder: data['display_order'] ?? 0,
  );
}

/// Convert icon name string to IconData
IconData _getIconFromString(String? iconName) {
  switch (iconName) {
    case 'kitchen':
      return Icons.kitchen;
    case 'fastfood':
      return Icons.fastfood;
    case 'spa':
      return Icons.spa;
    case 'devices':
      return Icons.devices;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'checkroom':
      return Icons.checkroom;
    case 'sports':
      return Icons.sports_cricket;
    case 'face':
      return Icons.face;
    case 'home':
      return Icons.home;
    case 'toys':
      return Icons.toys;
    default:
      return Icons.category;
  }
}

/// Convert hex color string to Color
Color _getColorFromHex(String? hexColor) {
  if (hexColor == null) return Colors.blue;

  try {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // Add alpha if not present
    }
    return Color(int.parse(hexColor, radix: 16));
  } catch (e) {
    return Colors.blue; // Fallback color
  }
}
