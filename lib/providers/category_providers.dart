import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/category_models.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Cached categories to avoid refetching
final categoriesCacheProvider = StateProvider<List<Category>?>((ref) => null);

// Selected category provider initialized with null
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Helper for icon conversion
IconData _getIconFromString(String? iconName) {
  switch (iconName) {
    case 'kitchen': return Icons.kitchen;
    case 'fastfood': return Icons.fastfood;
    case 'spa': return Icons.spa;
    case 'devices': return Icons.devices;
    case 'shopping_bag': return Icons.shopping_bag;
    case 'checkroom': return Icons.checkroom;
    case 'sports': return Icons.sports_cricket;
    case 'face': return Icons.face;
    case 'home': return Icons.home;
    case 'toys': return Icons.toys;
    default: return Icons.category;
  }
}

// Helper for color conversion
Color _getColorFromHex(String? hexColor) {
  if (hexColor == null) return Colors.grey;
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor'; // Add alpha if not present
  }
  return Color(int.parse(hexColor, radix: 16));
}

// Categories provider - updated to work with hierarchical categories
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    // Check if we have cached data
    final cachedCategories = ref.read(categoriesCacheProvider);
    if (cachedCategories != null) {
      print('🔄 Using cached categories data');
      return cachedCategories;
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    print('🔄 Fetching categories data from API');
    
    final supabase = Supabase.instance.client;
    
    // Get top-level categories
    final response = await supabase
        .from('categories')
        .select('id, name, icon_name, theme_color, image_url, display_order')
        .order('display_order');
    
    print('Retrieved ${response.length} categories');
    
    // Get all subcategories in one query
    List<dynamic> subCategoriesResponse = [];
    try {
      // Try getting subcategories from the subcategories table first
      subCategoriesResponse = await supabase
          .from('subcategories')
          .select('id, name, category_id, image_url, display_order, icon_name')
          .order('display_order');
      
      print('Retrieved ${subCategoriesResponse.length} subcategories from subcategories table');
    } catch (e) {
      print('Error fetching from subcategories table, falling back to old schema: $e');
      
      // Fall back to the old schema where subcategories are in the categories table
      subCategoriesResponse = await supabase
          .from('categories')
          .select('id, name, icon, theme_color, parent_id, product_count, image_url, display_order')
          .not('parent_id', 'is', null) // Get only subcategories
          .order('display_order');
      
      print('Retrieved ${subCategoriesResponse.length} subcategories from categories table');
    }
    
    // Convert to domain models
    final categories = response.map<Category>((json) {
      final categoryId = json['id'].toString();
      
      // Find subcategories for this parent
      List<SubCategory> subs = [];
      
      if (subCategoriesResponse.isNotEmpty) {
        // Check if we're using the new subcategories table
        if (subCategoriesResponse[0].containsKey('category_id')) {
          subs = subCategoriesResponse
              .where((sub) => sub['category_id'].toString() == categoryId)
              .map<SubCategory>((sub) => SubCategory(
                  id: sub['id'].toString(),
                  name: sub['name'],
                  parentId: categoryId,
                  imageUrl: sub['image_url'],
                  productCount: 0, // Not using product_count in new schema
              ))
              .toList();
        } else {
          // Using old schema
          subs = subCategoriesResponse
              .where((sub) => sub['parent_id'].toString() == categoryId)
              .map<SubCategory>((sub) => SubCategory(
                  id: sub['id'].toString(),
                  name: sub['name'],
                  parentId: sub['parent_id'].toString(),
                  imageUrl: sub['image_url'],
                  productCount: sub['product_count'] ?? 0,
              ))
              .toList();
        }
      }
      
      return Category(
        id: categoryId,
        name: json['name'],
        icon: _getIconFromString(json['icon_name'] ?? json['icon']),
        themeColor: _getColorFromHex(json['theme_color'] ?? '#4CAF50'),
        subCategories: subs,
      );
    }).toList();
    
    // Update cache state
    Future.microtask(() {
      ref.read(categoriesCacheProvider.notifier).state = categories;
    });
    
    return categories;
  } catch (e) {
    print('Error fetching categories: $e');
    rethrow;
  }
});

// This provider is used to initialize the selected category
// but does NOT modify state directly during initialization
final initializeSelectedCategoryProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<Category>>>(
    categoriesProvider, 
    (previous, next) {
      next.whenData((categories) {
        if (categories.isNotEmpty && ref.read(selectedCategoryProvider) == null) {
          // Use microtask to avoid modifying state during build
          Future.microtask(() {
            ref.read(selectedCategoryProvider.notifier).state = categories.first.id;
          });
        }
      });
    },
  );
  return null;
});

// Get subcategories for a specific category - updated for new schema
final subcategoriesProvider = FutureProvider.family<List<SubCategory>, String>((ref, categoryId) async {
  try {
    // Check if we have cached categories first
    final cachedCategories = ref.read(categoriesCacheProvider);
    if (cachedCategories != null) {
      // Find the selected category from cache
      final category = cachedCategories.firstWhere(
    (category) => category.id == categoryId,
        orElse: () => cachedCategories.first,
      );
      
      if (category.subCategories.isNotEmpty) {
        print('🔄 Using cached subcategories for ${category.name}');
  return category.subCategories;
      }
    }
    
    // If not in cache, fetch directly from database
    final supabase = Supabase.instance.client;
    
    print('🔄 Fetching subcategories for category $categoryId');
    
    try {
      // Fetch from subcategories table
      final response = await supabase
          .from('subcategories')
          .select('id, name, image_url, category_id')
          .eq('category_id', categoryId)
          .order('display_order');
      
      // Convert to domain models
      final subcategories = response.map<SubCategory>((json) => SubCategory(
          id: json['id'].toString(),
          name: json['name'],
          parentId: json['category_id'].toString(),
          imageUrl: json['image_url'],
          productCount: 0, // Not storing product_count in subcategories table
      )).toList();
      
      print('Found ${subcategories.length} subcategories for category $categoryId');
      return subcategories;
    } catch (e) {
      print('Error fetching from subcategories, falling back to categories table: $e');
      
      // Fall back to old approach if subcategories table doesn't exist
      final response = await supabase
          .from('categories')
          .select('id, name, icon, theme_color, parent_id, product_count, image_url')
          .eq('parent_id', categoryId)
          .order('display_order');
      
      // Convert to domain models
      final subcategories = response.map<SubCategory>((json) => SubCategory(
          id: json['id'].toString(),
          name: json['name'],
          parentId: json['parent_id'].toString(),
          imageUrl: json['image_url'],
          productCount: json['product_count'] ?? 0,
      )).toList();
      
      return subcategories;
    }
  } catch (e) {
    print('Error fetching subcategories: $e');
    rethrow;
  }
});

// Current selected category object (derived from selected ID)
final currentCategoryProvider = Provider<Category?>((ref) {
  final selectedId = ref.watch(selectedCategoryProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  
  return categoriesAsync.when(
    data: (categories) {
      if (categories.isEmpty) {
        return null;
      }
      return categories.firstWhere(
        (category) => category.id == selectedId,
        orElse: () => categories.first,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Helper function to navigate to subcategory
void navigateToSubcategory(BuildContext context, SubCategory subcategory) {
  context.go(
    '/category/${subcategory.id}',
    extra: {
      'name': subcategory.name,
      'parentCategory': subcategory.parentId,
    },
  );
}

// The rest of the mock data functions can be removed as we're now using real data 