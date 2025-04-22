import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/category.dart';
import '../../providers/clean_category_providers.dart';
import 'clean_subcategory_products_screen.dart';

class CleanCategoriesScreen extends ConsumerStatefulWidget {
  const CleanCategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanCategoriesScreen> createState() => _CleanCategoriesScreenState();
}

class _CleanCategoriesScreenState extends ConsumerState<CleanCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Load categories when the screen initializes
    Future.microtask(() => 
      ref.read(categoriesNotifierProvider.notifier).loadCategories()
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the categories state
    final categoriesState = ref.watch(categoriesNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: _buildBody(categoriesState),
    );
  }

  Widget _buildBody(CategoriesState state) {
    // Show loading state
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.errorMessage}', 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(categoriesNotifierProvider.notifier).loadCategories();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (state.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No categories found',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(categoriesNotifierProvider.notifier).loadCategories();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Show categories grid
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(categoriesNotifierProvider.notifier).loadCategories();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: state.categories.length,
        itemBuilder: (context, index) {
          final category = state.categories[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Select this category and navigate to subcategories
          ref.read(categoriesNotifierProvider.notifier).selectCategory(category.id);
          _navigateToSubcategories(category);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category icon
            Icon(
              category.icon ?? Icons.category,
              size: 48,
              color: category.themeColor ?? AppColors.primary,
            ),
            const SizedBox(height: 12),
            // Category name
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            // Subcategory count
            if (category.subCategories != null && category.subCategories!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${category.subCategories!.length} subcategories',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToSubcategories(Category category) {
    if (category.subCategories == null || category.subCategories!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No subcategories available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSubcategoriesBottomSheet(category),
    );
  }

  Widget _buildSubcategoriesBottomSheet(Category category) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${category.name} Subcategories',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${category.subCategories!.length} subcategories',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: category.subCategories!.length,
              itemBuilder: (context, index) {
                final subcategory = category.subCategories![index];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: subcategory.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(subcategory.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: subcategory.imageUrl == null
                          ? Colors.grey.shade200
                          : null,
                    ),
                    child: subcategory.imageUrl == null
                        ? const Icon(Icons.category, color: Colors.grey)
                        : null,
                  ),
                  title: Text(subcategory.name),
                  subtitle: subcategory.productCount != null
                      ? Text('${subcategory.productCount} products')
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CleanSubcategoryProductsScreen(
                          subcategoryId: subcategory.id,
                          subcategoryName: subcategory.name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 