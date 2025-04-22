import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/category.dart';
import '../../providers/clean_category_providers.dart';
import 'clean_subcategory_screen.dart';

class CleanCategoryScreen extends ConsumerStatefulWidget {
  const CleanCategoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanCategoryScreen> createState() => _CleanCategoryScreenState();
}

class _CleanCategoryScreenState extends ConsumerState<CleanCategoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load categories on initialization
    Future.microtask(() => 
      ref.read(categoriesNotifierProvider.notifier).loadCategories()
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the category state
    final categoryState = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(categoriesNotifierProvider.notifier).loadCategories();
            },
          ),
        ],
      ),
      body: _buildBody(categoryState),
    );
  }

  Widget _buildBody(CategoriesState state) {
    // Show loading state
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Set selected category and navigate to subcategory screen
          ref.read(categoriesNotifierProvider.notifier).selectCategory(category.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CleanSubcategoryScreen(
                categoryId: category.id,
                categoryName: category.name,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: category.themeColor?.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category icon with colored background
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: category.themeColor?.withOpacity(0.8) ?? Colors.blue.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon ?? Icons.category,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              // Category name
              Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              // Subcategory count if available
              if (category.subCategories != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${category.subCategories!.length} subcategories',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 