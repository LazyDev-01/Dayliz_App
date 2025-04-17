import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/category_models.dart';
import 'package:go_router/go_router.dart';

// Cached categories to avoid refetching
final categoriesCacheProvider = StateProvider<List<Category>?>((ref) => null);

// Selected category provider initialized with null
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Categories provider - IMPORTANT: doesn't modify state during initialization
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
    
    // Mock data (in a real app, this would be API call)
    final categories = _getCategories();
    
    // Update cache state *after* returning - this avoids the "provider modified during build" error
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

// Get subcategories for a specific category
final subcategoriesProvider = FutureProvider.family<List<SubCategory>, String>((ref, categoryId) async {
  try {
    // Get categories first
    final categories = await ref.watch(categoriesProvider.future);
    
    // Find the selected category
    final category = categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => categories.first,
    );
    
    // Simulate network delay for subcategories
    print('🔄 Fetching subcategories for ${category.name}');
    await Future.delayed(const Duration(milliseconds: 500));
    
    return category.subCategories;
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

// Helper function to get mock categories data
List<Category> _getCategories() {
  return [
    Category(
      id: 'grocery_kitchen',
      name: 'Grocery & Kitchen',
      icon: Icons.kitchen,
      themeColor: Colors.green.shade500,
      subCategories: [
        SubCategory(
          id: 'dairy_bread_eggs',
          name: 'Dairy, Bread & Eggs',
          parentId: 'grocery_kitchen',
          imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Dairy',
          productCount: 42,
        ),
        SubCategory(
          id: 'atta_rice_dal',
          name: 'Atta, Rice & Dal',
          parentId: 'grocery_kitchen',
          imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Rice',
          productCount: 38,
        ),
        SubCategory(
          id: 'oil_ghee_masala',
          name: 'Oil, Ghee & Masala',
          parentId: 'grocery_kitchen',
          imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Oil',
          productCount: 24,
        ),
        SubCategory(
          id: 'sauces_spreads',
          name: 'Sauces & Spreads',
          parentId: 'grocery_kitchen',
          imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Sauces',
          productCount: 18,
        ),
        SubCategory(
          id: 'frozen_food',
          name: 'Frozen Food',
          parentId: 'grocery_kitchen',
          imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Frozen',
          productCount: 15,
        ),
        SubCategory(
          id: 'vegetables_fruits',
          name: 'Vegetables & Fruits',
          parentId: 'grocery_kitchen',
          imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Veggies',
          productCount: 64,
        ),
      ],
    ),
    Category(
      id: 'snacks_beverages',
      name: 'Snacks & Beverages',
      icon: Icons.fastfood,
      themeColor: Colors.amber.shade600,
      subCategories: [
        SubCategory(
          id: 'cookies_biscuits',
          name: 'Cookies & Biscuits',
          parentId: 'snacks_beverages',
          imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Cookies',
          productCount: 32,
        ),
        SubCategory(
          id: 'snacks_chips',
          name: 'Snacks & Chips',
          parentId: 'snacks_beverages',
          imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Snacks',
          productCount: 47,
        ),
        SubCategory(
          id: 'cold_drinks_juices',
          name: 'Cold Drinks & Juices',
          parentId: 'snacks_beverages',
          imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Drinks',
          productCount: 28,
        ),
        SubCategory(
          id: 'coffee_tea',
          name: 'Coffee & Tea',
          parentId: 'snacks_beverages',
          imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Coffee',
          productCount: 19,
        ),
        SubCategory(
          id: 'ice_creams',
          name: 'Ice Creams & More',
          parentId: 'snacks_beverages',
          imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=IceCream',
          productCount: 22,
        ),
        SubCategory(
          id: 'chocolates_sweets',
          name: 'Chocolates & Sweets',
          parentId: 'snacks_beverages',
          imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Choco',
          productCount: 35,
        ),
      ],
    ),
    Category(
      id: 'beauty_hygiene',
      name: 'Beauty & Hygiene',
      icon: Icons.spa,
      themeColor: Colors.pink.shade400,
      subCategories: [
        SubCategory(
          id: 'bath_body',
          name: 'Bath & Body',
          parentId: 'beauty_hygiene',
          imageUrl: 'https://placehold.co/100/E91E63/FFFFFF?text=Bath',
          productCount: 29,
        ),
        SubCategory(
          id: 'skin_face_care',
          name: 'Skin & Face Care',
          parentId: 'beauty_hygiene',
          imageUrl: 'https://placehold.co/100/E91E63/FFFFFF?text=Skin',
          productCount: 43,
        ),
        SubCategory(
          id: 'hair_care',
          name: 'Hair Care',
          parentId: 'beauty_hygiene',
          imageUrl: 'https://placehold.co/100/E91E63/FFFFFF?text=Hair',
          productCount: 31,
        ),
        SubCategory(
          id: 'grooming_fragrances',
          name: 'Grooming & Fragrances',
          parentId: 'beauty_hygiene',
          imageUrl: 'https://placehold.co/100/E91E63/FFFFFF?text=Groom',
          productCount: 25,
        ),
        SubCategory(
          id: 'baby_care',
          name: 'Baby Care',
          parentId: 'beauty_hygiene',
          imageUrl: 'https://placehold.co/100/E91E63/FFFFFF?text=Baby',
          productCount: 18,
        ),
        SubCategory(
          id: 'beauty_cosmetics',
          name: 'Beauty & Cosmetics',
          parentId: 'beauty_hygiene',
          imageUrl: 'https://placehold.co/100/E91E63/FFFFFF?text=Beauty',
          productCount: 54,
        ),
      ],
    ),
    Category(
      id: 'household_essentials',
      name: 'Household & Essentials',
      icon: Icons.home,
      themeColor: Colors.purple.shade500,
      subCategories: [
        SubCategory(
          id: 'cleaning_supplies',
          name: 'Cleaning Supplies',
          parentId: 'household_essentials',
          imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Clean',
          productCount: 36,
        ),
        SubCategory(
          id: 'detergent_fabric_care',
          name: 'Detergent & Fabric Care',
          parentId: 'household_essentials',
          imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Detergent',
          productCount: 27,
        ),
        SubCategory(
          id: 'kitchen_accessories',
          name: 'Kitchen Accessories',
          parentId: 'household_essentials',
          imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Kitchen',
          productCount: 45,
        ),
        SubCategory(
          id: 'pet_care',
          name: 'Pet Care',
          parentId: 'household_essentials',
          imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Pet',
          productCount: 22,
        ),
      ],
    ),
  ];
} 