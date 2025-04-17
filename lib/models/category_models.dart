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