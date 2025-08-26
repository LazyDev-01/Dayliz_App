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
    // Filter for categories that should be shown in categories screen
    final response = await Supabase.instance.client
        .from('categories')
        .select('*, subcategories(*)')
        .eq('is_active', true)
        .eq('show_in_categories_screen', true)
        .order('display_order', ascending: true);

    debugPrint('🏷️ PROVIDER: Raw response: $response');
    // Convert to Category entities (already sorted by display_order from database)
    final categories = response.map((data) => _mapToCategory(data)).toList();

    debugPrint('🏷️ PROVIDER: Final categories order: ${categories.map((c) => '${c.name}(${c.displayOrder})').toList()}');

    return categories;
  } catch (e) {
    throw Exception('Failed to load categories: ${e.toString()}');
  }
});

/// Provider for service categories (for home screen Quick Services section)
/// Currently filtered to hide laundry and bakery services for MVP launch
final serviceCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    debugPrint('🏷️ SERVICE PROVIDER: Fetching service categories...');
    // Fetch service categories for home screen
    final response = await Supabase.instance.client
        .from('categories')
        .select('*, subcategories(*)')
        .eq('is_active', true)
        .eq('category_type', 'service')
        .order('display_order', ascending: true);

    debugPrint('🏷️ SERVICE PROVIDER: Raw response: $response');
    // Convert to Category entities
    final allCategories = response.map((data) => _mapToCategory(data)).toList();

    // Filter out laundry and bakery services for MVP launch
    final filteredCategories = allCategories.where((category) {
      final categoryName = category.name.toLowerCase();
      return !categoryName.contains('laundry') &&
             !categoryName.contains('bakery') &&
             !categoryName.contains('cake');
    }).toList();

    debugPrint('🏷️ SERVICE PROVIDER: Filtered service categories: ${filteredCategories.map((c) => c.name).toList()}');

    return filteredCategories;
  } catch (e) {
    throw Exception('Failed to load service categories: ${e.toString()}');
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

  // Helper for enum conversion
  CategoryType getCategoryType(String? type) {
    switch (type) {
      case 'service':
        return CategoryType.service;
      case 'product':
      default:
        return CategoryType.product;
    }
  }

  BusinessModel getBusinessModel(String? model) {
    switch (model) {
      case 'scheduled_service':
        return BusinessModel.scheduledService;
      case 'booking':
        return BusinessModel.booking;
      case 'reservation':
        return BusinessModel.reservation;
      case 'instant_delivery':
      default:
        return BusinessModel.instantDelivery;
    }
  }

  AvailabilityScope getAvailabilityScope(String? scope) {
    switch (scope) {
      case 'city_wide':
        return AvailabilityScope.cityWide;
      case 'zone_based':
      default:
        return AvailabilityScope.zoneBased;
    }
  }

  return Category(
    id: data['id'] ?? '',
    name: data['name'] ?? '',
    icon: _getIconFromString(data['icon_name']),
    themeColor: _getColorFromHex(data['theme_color']),
    imageUrl: data['image_url'],
    displayOrder: data['display_order'] ?? 0,
    categoryType: getCategoryType(data['category_type']),
    businessModel: getBusinessModel(data['business_model']),
    availabilityScope: getAvailabilityScope(data['availability_scope']),
    isActive: data['is_active'] ?? true,
    showInCategoriesScreen: data['show_in_categories_screen'] ?? true,
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
    case 'cake':
      return Icons.cake;
    case 'local_laundry_service':
      return Icons.local_laundry_service;
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
