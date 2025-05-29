import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/exceptions.dart';
import '../models/category_model.dart';
import 'category_remote_data_source.dart';

/// Supabase implementation of CategoryRemoteDataSource
class CategorySupabaseDataSource implements CategoryRemoteDataSource {
  final SupabaseClient supabaseClient;

  CategorySupabaseDataSource({required this.supabaseClient});

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await supabaseClient
          .from('categories')
          .select('*')
          .order('name'); // Order by name first, then we'll custom sort

      final categories = response.map((data) => _mapToCategory(data)).toList();

      // Custom sort to ensure correct order
      final sortedCategories = _sortCategoriesInCorrectOrder(categories);

      return sortedCategories;
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch categories from Supabase: ${e.toString()}',
      );
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final response = await supabaseClient
          .from('categories')
          .select('*')
          .eq('id', id)
          .single();

      return _mapToCategory(response);
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch category by ID from Supabase: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CategoryModel>> getCategoriesWithSubcategories() async {
    try {
      // Get categories with their subcategories
      // Don't rely on database display_order, we'll sort manually
      final response = await supabaseClient
          .from('categories')
          .select('*, subcategories(*)')
          .order('name'); // Order by name first, then we'll custom sort

      final categories = response.map((data) => _mapToCategoryWithSubcategories(data)).toList();

      // Custom sort to ensure correct order:
      // 1. Grocery & Kitchen
      // 2. Snacks & Drinks
      // 3. Beauty & Hygiene
      // 4. Household & Essentials
      final sortedCategories = _sortCategoriesInCorrectOrder(categories);

      return sortedCategories;
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch categories with subcategories from Supabase: ${e.toString()}',
      );
    }
  }

  /// Map Supabase data to CategoryModel
  CategoryModel _mapToCategory(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      icon: _getIconFromString(data['icon_name']),
      themeColor: _getColorFromHex(data['theme_color']),
      imageUrl: data['image_url'],
      displayOrder: data['display_order'] ?? 0,
    );
  }

  /// Map Supabase data to CategoryModel with subcategories
  CategoryModel _mapToCategoryWithSubcategories(Map<String, dynamic> data) {
    // Parse subcategories if available
    List<SubCategoryModel>? subcategories;
    if (data['subcategories'] != null) {
      final subcategoriesData = data['subcategories'] as List<dynamic>;
      subcategories = subcategoriesData
          .map((subData) => SubCategoryModel.fromJson(subData))
          .toList();

      // Sort subcategories by display order
      subcategories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }

    return CategoryModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      icon: _getIconFromString(data['icon_name']),
      themeColor: _getColorFromHex(data['theme_color']),
      imageUrl: data['image_url'],
      displayOrder: data['display_order'] ?? 0,
      subCategories: subcategories,
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

  /// Sort categories in the correct order regardless of database display_order
  List<CategoryModel> _sortCategoriesInCorrectOrder(List<CategoryModel> categories) {
    // Define the desired order
    final desiredOrder = [
      'Grocery & Kitchen',
      'Snacks & Drinks',
      'Beauty & Hygiene',
      'Household & Essentials'
    ];

    // Create a map for quick lookup
    final categoryMap = <String, CategoryModel>{};
    for (final category in categories) {
      categoryMap[category.name] = category;
    }

    // Build the sorted list
    final sortedCategories = <CategoryModel>[];

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
}
