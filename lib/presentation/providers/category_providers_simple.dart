import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/category.dart';

/// Simple provider that directly fetches categories from Supabase
/// This bypasses the complex dependency injection chain for now
final categoriesSimpleProvider = FutureProvider<List<Category>>((ref) async {
  try {
    debugPrint('CategoriesSimpleProvider: Starting to fetch categories...');

    // Fetch categories with subcategories from Supabase
    // Don't rely on database display_order, we'll sort manually
    final response = await Supabase.instance.client
        .from('categories')
        .select('*, subcategories(*)')
        .order('name'); // Order by name first, then we'll custom sort

    debugPrint('CategoriesSimpleProvider: Received ${response.length} categories');

    // Convert to Category entities
    final categories = response.map((data) => _mapToCategory(data)).toList();

    // Custom sort to ensure correct order:
    // 1. Grocery & Kitchen
    // 2. Snacks & Drinks
    // 3. Beauty & Hygiene
    // 4. Household & Essentials
    final sortedCategories = _sortCategoriesInCorrectOrder(categories);

    debugPrint('CategoriesSimpleProvider: Successfully mapped and sorted ${sortedCategories.length} categories');
    for (int i = 0; i < sortedCategories.length; i++) {
      debugPrint('Category ${i + 1}: ${sortedCategories[i].name}');
    }

    return sortedCategories;
  } catch (e) {
    debugPrint('CategoriesSimpleProvider: Error loading categories: $e');
    throw Exception('Failed to load categories: ${e.toString()}');
  }
});

/// Sort categories in the correct order regardless of database display_order
List<Category> _sortCategoriesInCorrectOrder(List<Category> categories) {
  // Define the desired order
  final desiredOrder = [
    'Grocery & Kitchen',
    'Snacks & Drinks',
    'Beauty & Hygiene',
    'Household & Essentials'
  ];

  // Create a map for quick lookup
  final categoryMap = <String, Category>{};
  for (final category in categories) {
    categoryMap[category.name] = category;
  }

  // Build the sorted list
  final sortedCategories = <Category>[];

  // Add categories in the desired order
  for (final categoryName in desiredOrder) {
    if (categoryMap.containsKey(categoryName)) {
      sortedCategories.add(categoryMap[categoryName]!);
      categoryMap.remove(categoryName); // Remove to avoid duplicates
    }
  }

  // Add any remaining categories that weren't in our desired order
  sortedCategories.addAll(categoryMap.values);

  return sortedCategories;
}

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
