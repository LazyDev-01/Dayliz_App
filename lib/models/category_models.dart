import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color themeColor;
  final List<SubCategory> subCategories;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.themeColor,
    this.subCategories = const [],
  });
  
  // Add fromJson method for database conversion
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(), // Convert UUID to string if needed
      name: json['name'],
      icon: _getIconFromString(json['icon']), // Helper to convert string to IconData
      themeColor: _getColorFromHex(json['theme_color']), // Helper to convert hex to Color
      subCategories: const [], // Subategories are loaded separately
    );
  }
  
  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': _getStringFromIcon(icon),
      'theme_color': _getHexFromColor(themeColor),
    };
  }
  
  // Helper for icon name extraction
  static String _getStringFromIcon(IconData icon) {
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
}

class SubCategory {
  final String id;
  final String name;
  final String parentId;
  final String? imageUrl;
  final int productCount;

  const SubCategory({
    required this.id,
    required this.name,
    required this.parentId,
    this.imageUrl,
    this.productCount = 0,
  });
  
  // Add fromJson method for database conversion
  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'].toString(), // Convert UUID to string if needed
      name: json['name'],
      parentId: json['parent_id'].toString(),
      imageUrl: json['image_url'],
      productCount: json['product_count'] ?? 0,
    );
  }
  
  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parent_id': parentId,
      'image_url': imageUrl,
    };
  }
}

// Helper for icon conversion - used by fromJson methods
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

// Helper for color conversion - used by fromJson methods
Color _getColorFromHex(String? hexColor) {
  if (hexColor == null) return Colors.grey;
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor'; // Add alpha if not present
  }
  return Color(int.parse(hexColor, radix: 16));
}

// Helper for color to hex conversion
String _getHexFromColor(Color color) {
  return '#${color.value.toRadixString(16).substring(2)}';
}

// Extension for color manipulation
extension ColorExtension on Color {
  Color getLighter(double factor) {
    assert(factor >= 0 && factor <= 1);
    
    int r = this.red;
    int g = this.green;
    int b = this.blue;
    
    r = r + ((255 - r) * factor).round();
    g = g + ((255 - g) * factor).round();
    b = b + ((255 - b) * factor).round();
    
    return Color.fromARGB(this.alpha, r, g, b);
  }
  
  Color getDarker(double factor) {
    assert(factor >= 0 && factor <= 1);
    
    int r = this.red;
    int g = this.green;
    int b = this.blue;
    
    r = (r * (1 - factor)).round();
    g = (g * (1 - factor)).round();
    b = (b * (1 - factor)).round();
    
    return Color.fromARGB(this.alpha, r, g, b);
  }
} 