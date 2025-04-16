import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:flutter/animation.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';

class Category {
  final String id;
  final String name;
  final List<SubCategory> subCategories;
  final IconData icon;
  final Color themeColor;

  Category({
    required this.id,
    required this.name,
    required this.subCategories,
    required this.icon,
    required this.themeColor,
  });
}

class SubCategory {
  final String id;
  final String name;
  final String parentId;
  final String? imageUrl;
  final int productCount;

  SubCategory({
    required this.id,
    required this.name,
    required this.parentId,
    this.imageUrl,
    required this.productCount,
  });
}

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  CategoriesScreenState createState() => CategoriesScreenState();
}

class CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late List<Category> _categories;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _categories = _getCategories();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Set initial selected category
    Future.microtask(() {
      if (_categories.isNotEmpty && ref.read(selectedCategoryProvider) == null) {
        ref.read(selectedCategoryProvider.notifier).state = _categories.first.id;
      }
      _animationController.forward();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Method to get lighter variant of a color
  Color _getLighterColor(Color color, [double factor = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + factor).clamp(0.0, 1.0)).toColor();
  }

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
        themeColor: Colors.blue.shade500,
        subCategories: [
          SubCategory(
            id: 'bath_body',
            name: 'Bath & Body',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Bath',
            productCount: 29,
          ),
          SubCategory(
            id: 'skin_face_care',
            name: 'Skin & Face Care',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Skin',
            productCount: 43,
          ),
          SubCategory(
            id: 'hair_care',
            name: 'Hair Care',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Hair',
            productCount: 31,
          ),
          SubCategory(
            id: 'grooming_fragrances',
            name: 'Grooming & Fragrances',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Groom',
            productCount: 25,
          ),
          SubCategory(
            id: 'baby_care',
            name: 'Baby Care',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Baby',
            productCount: 18,
          ),
          SubCategory(
            id: 'beauty_cosmetics',
            name: 'Beauty & Cosmetics',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Beauty',
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

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    // Find the currently selected category
    Category? currentCategory = _categories.firstWhere(
      (category) => category.id == selectedCategory,
      orElse: () => _categories.first,
    );
    
    // When category changes, restart the animation
    ref.listen<String?>(selectedCategoryProvider, (previous, current) {
      if (previous != current) {
        _animationController.reset();
        _animationController.forward();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Categories',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: currentCategory.themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Category sidebar
          SizedBox(
            width: 80,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(1, 0),
                  ),
                ],
              ),
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category.id == selectedCategory;
                  
                  return InkWell(
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = category.id;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? _getLighterColor(category.themeColor, 0.8) : Colors.transparent,
                        border: Border(
                          right: BorderSide(
                            color: isSelected ? category.themeColor : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            category.icon,
                            color: isSelected ? category.themeColor : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            category.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? category.themeColor : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Subcategories grid
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: child,
                  ),
                );
              },
              child: Container(
                color: _getLighterColor(currentCategory.themeColor, 0.85),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            currentCategory.icon,
                            color: currentCategory.themeColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentCategory.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: currentCategory.themeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: currentCategory.subCategories.length,
                          itemBuilder: (context, index) {
                            final subCategory = currentCategory.subCategories[index];
                            return InkWell(
                              onTap: () {
                                // Navigate to product listing screen with category ID and name
                                context.go(
                                  '/category/${subCategory.id}',
                                  extra: {
                                    'name': subCategory.name,
                                    'parentCategory': currentCategory.name,
                                  },
                                );
                              },
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        subCategory.imageUrl ?? 'https://placehold.co/100/CCCCCC/FFFFFF?text=No+Image',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        subCategory.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 