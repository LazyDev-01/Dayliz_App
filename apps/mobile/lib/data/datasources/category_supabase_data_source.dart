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
      debugPrint('🏷️ CATEGORIES: Fetching categories with display_order...');
      final response = await supabaseClient
          .from('categories')
          .select('*')
          .order('display_order', ascending: true); // Explicitly order ascending by display_order

      debugPrint('🏷️ CATEGORIES: Raw response: $response');
      final categories = response.map((data) => _mapToCategory(data)).toList();

      debugPrint('🏷️ CATEGORIES: Mapped categories order: ${categories.map((c) => '${c.name}(${c.displayOrder})').toList()}');

      // Return categories already sorted by database display_order
      return categories;
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
          .order('display_order', ascending: true); // Explicitly order ascending by display_order

      final categories = response.map((data) => _mapToCategoryWithSubcategories(data)).toList();

      // Return categories already sorted by database display_order
      return categories;
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


}
