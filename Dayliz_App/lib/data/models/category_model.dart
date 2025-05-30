import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

/// CategoryModel class extending Category entity for data layer operations
class CategoryModel extends Category {
  const CategoryModel({
    required String id,
    required String name,
    required IconData icon,
    required Color themeColor,
    String? imageUrl,
    int displayOrder = 0,
    List<SubCategoryModel>? subCategories,
  }) : super(
          id: id,
          name: name,
          icon: icon,
          themeColor: themeColor,
          imageUrl: imageUrl,
          displayOrder: displayOrder,
          subCategories: subCategories,
        );

  /// Create a CategoryModel from a JSON map
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // Convert subcategories if present
    final List<SubCategoryModel> subcategories = [];
    if (json['subcategories'] != null) {
      for (var subcat in json['subcategories']) {
        subcategories.add(SubCategoryModel.fromJson(subcat));
      }
    }
    
    // Helper for icon conversion
    IconData getIconFromString(String? iconName) {
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
    Color getColorFromHex(String? hexColor) {
      if (hexColor == null) return Colors.blue;
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Add alpha if not present
      }
      return Color(int.parse(hexColor, radix: 16));
    }

    return CategoryModel(
      id: json['id'],
      name: json['name'],
      icon: getIconFromString(json['icon_name'] ?? json['icon']),
      themeColor: getColorFromHex(json['theme_color']),
      imageUrl: json['image_url'],
      displayOrder: json['display_order'] ?? 0,
      subCategories: subcategories,
    );
  }

  /// Convert a CategoryModel to a JSON map
  Map<String, dynamic> toJson() {
    // Helper to get string representation of icon
    String getIconString(IconData icon) {
      if (icon == Icons.kitchen) return 'kitchen';
      if (icon == Icons.fastfood) return 'fastfood';
      if (icon == Icons.spa) return 'spa';
      if (icon == Icons.devices) return 'devices';
      if (icon == Icons.shopping_bag) return 'shopping_bag';
      if (icon == Icons.checkroom) return 'checkroom';
      if (icon == Icons.sports_cricket) return 'sports';
      if (icon == Icons.face) return 'face';
      if (icon == Icons.home) return 'home';
      if (icon == Icons.toys) return 'toys';
      return 'category';
    }
    
    // Helper to convert color to hex
    String colorToHex(Color color) {
      return '#${color.value.toRadixString(16).substring(2)}';
    }
    
    return {
      'id': id,
      'name': name,
      'icon_name': getIconString(icon),
      'theme_color': colorToHex(themeColor),
      'image_url': imageUrl,
      'display_order': displayOrder,
      'subcategories': subCategories != null
          ? subCategories!.map((subcat) => (subcat as SubCategoryModel).toJson()).toList()
          : [],
    };
  }
}

/// SubCategory model class extending SubCategory entity for data layer operations
class SubCategoryModel extends SubCategory {
  const SubCategoryModel({
    required String id,
    required String name,
    required String parentId,
    String? imageUrl,
    String? iconName,
    int displayOrder = 0,
    int productCount = 0,
  }) : super(
          id: id,
          name: name,
          parentId: parentId,
          imageUrl: imageUrl,
          iconName: iconName,
          displayOrder: displayOrder,
          productCount: productCount,
        );

  /// Create a SubCategoryModel from a JSON map
  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json['id'],
      name: json['name'],
      parentId: json['category_id'] ?? json['parent_id'],
      imageUrl: json['image_url'],
      iconName: json['icon_name'],
      displayOrder: json['display_order'] ?? 0,
      productCount: json['product_count'] ?? 0,
    );
  }

  /// Convert a SubCategoryModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': parentId,
      'image_url': imageUrl,
      'icon_name': iconName,
      'display_order': displayOrder,
      'product_count': productCount,
    };
  }
} 