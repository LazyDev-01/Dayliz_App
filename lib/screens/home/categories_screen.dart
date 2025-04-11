import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/theme/app_theme.dart';

class Category {
  final String id;
  final String name;
  final List<SubCategory> subCategories;
  final IconData icon;

  Category({
    required this.id,
    required this.name,
    required this.subCategories,
    required this.icon,
  });
}

class SubCategory {
  final String id;
  final String name;
  final String parentId;
  final String? imageUrl;

  SubCategory({
    required this.id,
    required this.name,
    required this.parentId,
    this.imageUrl,
  });
}

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  CategoriesScreenState createState() => CategoriesScreenState();
}

class CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  late List<Category> _categories;

  @override
  void initState() {
    super.initState();
    _categories = _getCategories();
    
    // Set initial selected category
    Future.microtask(() {
      if (_categories.isNotEmpty && ref.read(selectedCategoryProvider) == null) {
        ref.read(selectedCategoryProvider.notifier).state = _categories.first.id;
      }
    });
  }

  List<Category> _getCategories() {
    return [
      Category(
        id: 'grocery_kitchen',
        name: 'Grocery & Kitchen',
        icon: Icons.kitchen,
        subCategories: [
          SubCategory(
            id: 'dairy_bread_eggs',
            name: 'Dairy, Bread & Eggs',
            parentId: 'grocery_kitchen',
            imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Dairy',
          ),
          SubCategory(
            id: 'atta_rice_dal',
            name: 'Atta, Rice & Dal',
            parentId: 'grocery_kitchen',
            imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Rice',
          ),
          SubCategory(
            id: 'oil_ghee_masala',
            name: 'Oil, Ghee & Masala',
            parentId: 'grocery_kitchen',
            imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Oil',
          ),
          SubCategory(
            id: 'sauces_spreads',
            name: 'Sauces & Spreads',
            parentId: 'grocery_kitchen',
            imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Sauces',
          ),
          SubCategory(
            id: 'frozen_food',
            name: 'Frozen Food',
            parentId: 'grocery_kitchen',
            imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Frozen',
          ),
          SubCategory(
            id: 'vegetables_fruits',
            name: 'Vegetables & Fruits',
            parentId: 'grocery_kitchen',
            imageUrl: 'https://placehold.co/100/4CAF50/FFFFFF?text=Veggies',
          ),
        ],
      ),
      Category(
        id: 'snacks_beverages',
        name: 'Snacks & Beverages',
        icon: Icons.fastfood,
        subCategories: [
          SubCategory(
            id: 'cookies_biscuits',
            name: 'Cookies & Biscuits',
            parentId: 'snacks_beverages',
            imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Cookies',
          ),
          SubCategory(
            id: 'snacks_chips',
            name: 'Snacks & Chips',
            parentId: 'snacks_beverages',
            imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Snacks',
          ),
          SubCategory(
            id: 'cold_drinks_juices',
            name: 'Cold Drinks & Juices',
            parentId: 'snacks_beverages',
            imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Drinks',
          ),
          SubCategory(
            id: 'coffee_tea',
            name: 'Coffee & Tea',
            parentId: 'snacks_beverages',
            imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Coffee',
          ),
          SubCategory(
            id: 'ice_creams',
            name: 'Ice Creams & More',
            parentId: 'snacks_beverages',
            imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=IceCream',
          ),
          SubCategory(
            id: 'chocolates_sweets',
            name: 'Chocolates & Sweets',
            parentId: 'snacks_beverages',
            imageUrl: 'https://placehold.co/100/FFC107/FFFFFF?text=Choco',
          ),
        ],
      ),
      Category(
        id: 'beauty_hygiene',
        name: 'Beauty & Hygiene',
        icon: Icons.spa,
        subCategories: [
          SubCategory(
            id: 'bath_body',
            name: 'Bath & Body',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Bath',
          ),
          SubCategory(
            id: 'skin_face_care',
            name: 'Skin & Face Care',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Skin',
          ),
          SubCategory(
            id: 'hair_care',
            name: 'Hair Care',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Hair',
          ),
          SubCategory(
            id: 'grooming_fragrances',
            name: 'Grooming & Fragrances',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Groom',
          ),
          SubCategory(
            id: 'baby_care',
            name: 'Baby Care',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Baby',
          ),
          SubCategory(
            id: 'beauty_cosmetics',
            name: 'Beauty & Cosmetics',
            parentId: 'beauty_hygiene',
            imageUrl: 'https://placehold.co/100/2196F3/FFFFFF?text=Beauty',
          ),
        ],
      ),
      Category(
        id: 'household_essentials',
        name: 'Household & Essentials',
        icon: Icons.home,
        subCategories: [
          SubCategory(
            id: 'cleaning_supplies',
            name: 'Cleaning Supplies',
            parentId: 'household_essentials',
            imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Clean',
          ),
          SubCategory(
            id: 'detergent_fabric_care',
            name: 'Detergent & Fabric Care',
            parentId: 'household_essentials',
            imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Detergent',
          ),
          SubCategory(
            id: 'kitchen_accessories',
            name: 'Kitchen Accessories',
            parentId: 'household_essentials',
            imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Kitchen',
          ),
          SubCategory(
            id: 'pet_care',
            name: 'Pet Care',
            parentId: 'household_essentials',
            imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Pet',
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    Category? currentCategory = _categories.firstWhere(
      (category) => category.id == selectedCategory,
      orElse: () => _categories.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Row(
        children: [
          // Category sidebar
          SizedBox(
            width: 100,
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category.id == selectedCategory;
                
                return InkWell(
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state = category.id;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLightColor : Colors.transparent,
                      border: Border(
                        right: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          category.icon,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryColor : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Subcategories grid
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentCategory.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: currentCategory.subCategories.length,
                        itemBuilder: (context, index) {
                          final subCategory = currentCategory.subCategories[index];
                          return InkWell(
                            onTap: () {
                              // TODO: Navigate to subcategory products
                            },
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      subCategory.imageUrl ?? 'https://placehold.co/100/CCCCCC/FFFFFF?text=No+Image',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      subCategory.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
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
        ],
      ),
    );
  }
} 