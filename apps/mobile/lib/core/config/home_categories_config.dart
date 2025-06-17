import 'package:flutter/material.dart';

/// Configuration for home screen categories with hybrid approach
/// Combines direct subcategories and virtual categories for better UX
/// Uses actual Supabase UUID format subcategory IDs
class HomeCategoriesConfig {
  /// Home screen category item with real Supabase UUIDs
  static const List<HomeCategory> homeCategories = [
    HomeCategory(
      id: 'breakfast',
      name: 'Breakfast',
      icon: Icons.breakfast_dining,
      color: Color(0xFFFF9800), // Orange
      isVirtual: true,
      subcategoryIds: [
        '5959ce47-3505-4f12-abcf-05d92483fed5', // Dairy, Bread & Eggs
        'c0078fb8-130b-47c4-8de4-0b76f7136a2a', // Sauces and Spreads
      ],
      subcategoryNames: ['Dairy, Bread & Eggs', 'Sauces and Spreads'],
    ),
    HomeCategory(
      id: 'cooking_essentials',
      name: 'Cooking Essentials',
      icon: Icons.rice_bowl,
      color: Color(0xFF4CAF50), // Green
      isVirtual: true,
      subcategoryIds: [
        '1b614fbd-5a8a-4d91-a22a-29b9441f8d8e', // Atta, Rice & Dal
        '260b6496-4a84-4d5c-87ae-cd8bafae1838', // Oils & Ghee
      ],
      subcategoryNames: ['Atta, Rice & Dal', 'Oils & Ghee'],
    ),
    HomeCategory(
      id: 'snacks_drinks',
      name: 'Snacks & Drinks',
      icon: Icons.local_drink,
      color: Color(0xFFE91E63), // Pink
      isVirtual: true,
      subcategoryIds: [
        '9763d7cc-bec0-4247-af85-8964119423e5', // Chips & Namkeens
        'a59c485e-684a-44a2-a70a-d850d0b8a78d', // Cold Drinks & Juices
      ],
      subcategoryNames: ['Chips & Namkeens', 'Cold Drinks & Juices'],
    ),
    HomeCategory(
      id: 'instant_food',
      name: 'Instant Food',
      icon: Icons.ramen_dining,
      color: Color(0xFF9C27B0), // Purple
      isVirtual: false,
      subcategoryIds: [
        '3dd438fc-6726-4774-b8d6-8ebb4b75eef8', // Noodles, Pasta & More
      ],
      subcategoryNames: ['Noodles, Pasta & More'],
    ),
    HomeCategory(
      id: 'personal_care',
      name: 'Personal Care',
      icon: Icons.face_retouching_natural,
      color: Color(0xFF2196F3), // Blue
      isVirtual: true,
      subcategoryIds: [
        'c3103078-edf8-4bd2-ba73-45a20facf325', // Skin Care
        'a18e9184-eef2-4b59-8653-4bd2992e7ea7', // Fragrances
      ],
      subcategoryNames: ['Skin Care', 'Fragrances'],
    ),
    HomeCategory(
      id: 'pet_supplies',
      name: 'Pet Supplies',
      icon: Icons.pets,
      color: Color(0xFF795548), // Brown
      isVirtual: false,
      subcategoryIds: [
        '6d60b661-1eb3-4f39-9003-6336a7c79f6e', // Pet Supplies
      ],
      subcategoryNames: ['Pet Supplies'],
    ),
    HomeCategory(
      id: 'household',
      name: 'Household',
      icon: Icons.cleaning_services,
      color: Color(0xFF607D8B), // Blue Grey
      isVirtual: false,
      subcategoryIds: [
        'a02a2c39-ea82-484e-9c48-57d37fa1dcf9', // Cleaning Essentials
      ],
      subcategoryNames: ['Cleaning Essentials'],
    ),
    HomeCategory(
      id: 'fresh',
      name: 'Fresh',
      icon: Icons.eco,
      color: Color(0xFF8BC34A), // Light Green
      isVirtual: false,
      subcategoryIds: [
        'c1535044-5545-4e03-9cce-9f2fb42dafed', // Fruits & Vegetables
      ],
      subcategoryNames: ['Fruits & Vegetables'],
    ),
  ];

  /// Get subcategory IDs for a home category
  static List<String> getSubcategoryIds(String homeCategoryId) {
    final category = homeCategories.firstWhere(
      (cat) => cat.id == homeCategoryId,
      orElse: () => throw Exception('Home category not found: $homeCategoryId'),
    );
    return category.subcategoryIds;
  }

  /// Get subcategory names for a home category
  static List<String> getSubcategoryNames(String homeCategoryId) {
    final category = homeCategories.firstWhere(
      (cat) => cat.id == homeCategoryId,
      orElse: () => throw Exception('Home category not found: $homeCategoryId'),
    );
    return category.subcategoryNames;
  }

  /// Check if a home category is virtual (combines multiple subcategories)
  static bool isVirtualCategory(String homeCategoryId) {
    final category = homeCategories.firstWhere(
      (cat) => cat.id == homeCategoryId,
      orElse: () => throw Exception('Home category not found: $homeCategoryId'),
    );
    return category.isVirtual;
  }

  /// Get home category by ID
  static HomeCategory? getHomeCategoryById(String id) {
    try {
      return homeCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Home screen category data class
class HomeCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isVirtual;
  final List<String> subcategoryIds;
  final List<String> subcategoryNames;

  const HomeCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isVirtual,
    required this.subcategoryIds,
    required this.subcategoryNames,
  });

  /// Get display title for navigation
  String get displayTitle {
    if (isVirtual) {
      return name; // Use the virtual category name
    } else {
      return subcategoryNames.first; // Use the actual subcategory name
    }
  }

  /// Get query parameters for product listing
  Map<String, String> get queryParams {
    if (isVirtual) {
      // For virtual categories, pass multiple subcategory IDs
      return {
        'subcategories': subcategoryIds.join(','),
        'title': name,
        'virtual': 'true',
      };
    } else {
      // For direct subcategories, pass single subcategory ID
      return {
        'subcategory': subcategoryIds.first,
        'title': subcategoryNames.first,
        'virtual': 'false',
      };
    }
  }
}
