import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

/// Mock data for categories and subcategories
class MockCategories {
  /// Get mock category sections with their subcategories
  static List<CategorySection> getCategorySections() {
    return [
      CategorySection(
        id: '1',
        name: 'Grocery & Kitchen',
        icon: Icons.kitchen,
        themeColor: Colors.green,
        subcategories: [
          SubCategory(
            id: '101',
            name: 'Fruits & Vegetables',
            parentId: '1',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'vegetables',
            productCount: 48,
          ),
          SubCategory(
            id: '102',
            name: 'Dairy, Bread & Eggs',
            parentId: '1',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'dairy',
            productCount: 36,
          ),
          SubCategory(
            id: '103',
            name: 'Cereals & meals',
            parentId: '1',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'cereals',
            productCount: 32,
          ),
          SubCategory(
            id: '104',
            name: 'Atta, Rice & Dal',
            parentId: '1',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'rice',
            productCount: 24,
          ),
          SubCategory(
            id: '105',
            name: 'Oils & Ghee',
            parentId: '1',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'oil',
            productCount: 20,
          ),
          SubCategory(
            id: '106',
            name: 'Masala & Spices',
            parentId: '1',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'spices',
            productCount: 28,
          ),
          SubCategory(
            id: '107',
            name: 'Sauces and Spreads',
            parentId: '1',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'sauces',
            productCount: 16,
          ),
          SubCategory(
            id: '108',
            name: 'Frozen Food',
            parentId: '1',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'frozen',
            productCount: 12,
          ),
        ],
      ),
      CategorySection(
        id: '2',
        name: 'Snacks & Drinks',
        icon: Icons.fastfood,
        themeColor: Colors.orange,
        subcategories: [
          SubCategory(
            id: '201',
            name: 'Cookies & Biscuits',
            parentId: '2',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'cookies',
            productCount: 32,
          ),
          SubCategory(
            id: '202',
            name: 'Noodles, Pasta & More',
            parentId: '2',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'noodles',
            productCount: 24,
          ),
          SubCategory(
            id: '203',
            name: 'Chips & Namkeens',
            parentId: '2',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'chips',
            productCount: 28,
          ),
          SubCategory(
            id: '204',
            name: 'Cold Drinks & Juices',
            parentId: '2',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'drinks',
            productCount: 24,
          ),
          SubCategory(
            id: '205',
            name: 'Chocolates',
            parentId: '2',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'chocolates',
            productCount: 22,
          ),
          SubCategory(
            id: '206',
            name: 'Ice Creams and more',
            parentId: '2',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'icecream',
            productCount: 20,
          ),
          SubCategory(
            id: '207',
            name: 'Tea & Coffee',
            parentId: '2',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'tea',
            productCount: 16,
          ),
          SubCategory(
            id: '208',
            name: 'Sweets',
            parentId: '2',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'sweets',
            productCount: 18,
          ),
        ],
      ),
      CategorySection(
        id: '3',
        name: 'Beauty & Hygiene',
        icon: Icons.spa,
        themeColor: Colors.purple,
        subcategories: [
          SubCategory(
            id: '301',
            name: 'Bath and Body',
            parentId: '3',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'bath',
            productCount: 30,
          ),
          SubCategory(
            id: '302',
            name: 'Skin Care',
            parentId: '3',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'skincare',
            productCount: 28,
          ),
          SubCategory(
            id: '303',
            name: 'Hair Care',
            parentId: '3',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'haircare',
            productCount: 24,
          ),
          SubCategory(
            id: '304',
            name: 'Oral Care',
            parentId: '3',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'oral',
            productCount: 20,
          ),
          SubCategory(
            id: '305',
            name: 'Fragrances',
            parentId: '3',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'fragrances',
            productCount: 16,
          ),
          SubCategory(
            id: '306',
            name: 'Baby Care',
            parentId: '3',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'babycare',
            productCount: 18,
          ),
          SubCategory(
            id: '307',
            name: 'Grooming',
            parentId: '3',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'grooming',
            productCount: 22,
          ),
          SubCategory(
            id: '308',
            name: 'Cosmetics',
            parentId: '3',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'cosmetics',
            productCount: 32,
          ),
        ],
      ),
      CategorySection(
        id: '4',
        name: 'Household & Essentials',
        icon: Icons.home,
        themeColor: Colors.blue,
        subcategories: [
          SubCategory(
            id: '401',
            name: 'Cleaning Essentials',
            parentId: '4',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'cleaning',
            productCount: 24,
          ),
          SubCategory(
            id: '402',
            name: 'Kitchen & Dining',
            parentId: '4',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'kitchen',
            productCount: 20,
          ),
          SubCategory(
            id: '403',
            name: 'Stationeries',
            parentId: '4',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'stationery',
            productCount: 15,
          ),
          SubCategory(
            id: '404',
            name: 'Pet Supplies',
            parentId: '4',
            imageUrl: 'https://via.placeholder.com/150',
            iconName: 'pet',
            productCount: 16,
          ),
        ],
      ),
    ];
  }
}

/// Represents a category section containing multiple subcategories
class CategorySection {
  final String id;
  final String name;
  final IconData icon;
  final Color themeColor;
  final List<SubCategory> subcategories;

  CategorySection({
    required this.id,
    required this.name,
    required this.icon,
    required this.themeColor,
    required this.subcategories,
  });
}
