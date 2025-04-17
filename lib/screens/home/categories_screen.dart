import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:flutter/animation.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dayliz_app/models/category_models.dart';
import 'package:dayliz_app/providers/search_providers.dart';
import 'package:dayliz_app/providers/category_providers.dart';
import 'package:visibility_detector/visibility_detector.dart';

// We'll use the selectedCategoryProvider from category_providers.dart
// final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Adding navigateToSubcategory method
  void navigateToSubcategory(BuildContext context, SubCategory subcategory) {
    context.go(
      '/category/${subcategory.id}',
      extra: {
        'name': subcategory.name,
        'parentCategory': subcategory.parentId,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Start animation
    _animationController.forward();
    
    // Force initialization of the categories provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(categoriesProvider).hasValue) {
        ref.read(categoriesProvider);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We depend on the loading state and categories data
    final categoriesData = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Category sidebar
          SizedBox(
            width: 80,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: categoriesData.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (categories) => ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category.id == selectedCategoryId;
                    
                    return InkWell(
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).state = category.id;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.themeColor.withOpacity(0.1)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? category.themeColor : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              category.icon,
                              color: isSelected ? category.themeColor : Colors.grey,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.name.split(' ')[0],
                              style: TextStyle(
                                color: isSelected ? category.themeColor : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Subcategories section
          Expanded(
            child: _buildSubcategoriesSection(selectedCategoryId),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoriesSection(String? selectedCategoryId) {
    if (selectedCategoryId == null) {
      return const Center(
        child: Text('Select a category'),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Consumer(
          builder: (context, ref, child) {
            final subcategoriesAsync = ref.watch(
              subcategoriesProvider(selectedCategoryId),
            );

            return subcategoriesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
              data: (subcategories) {
                if (subcategories.isEmpty) {
                  return const Center(
                    child: Text('No subcategories found'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = subcategories[index];
                    return _buildSubcategoryCard(subcategory);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubcategoryCard(SubCategory subcategory) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Use the navigation function
          navigateToSubcategory(context, subcategory);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: subcategory.imageUrl ?? 'https://placehold.co/400x300/CCCCCC/FFFFFF?text=No+Image',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subcategory.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subcategory.productCount} Products',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Search modal component
class CategorySearchModal extends ConsumerStatefulWidget {
  final Category parentCategory;
  
  const CategorySearchModal({
    Key? key,
    required this.parentCategory,
  }) : super(key: key);
  
  @override
  CategorySearchModalState createState() => CategorySearchModalState();
}

class CategorySearchModalState extends ConsumerState<CategorySearchModal> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Set focus on the search field when modal opens
    Future.microtask(() {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: widget.parentCategory.themeColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.parentCategory.icon,
                        color: widget.parentCategory.themeColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search in ${widget.parentCategory.name}',
                        style: TextStyle(
                          color: widget.parentCategory.themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search input
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                  ),
                ],
              ),
            ),
            
            // Search results
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final searchQuery = ref.watch(debouncedSearchQueryProvider);
                  
                  if (searchQuery.isEmpty) {
                    return _buildSearchHint();
                  }
                  
                  final searchResults = ref.watch(subcategorySearchResultsProvider);
                  
                  return searchResults.when(
                    data: (results) {
                      if (results.isEmpty) {
                        return _buildNoResults(searchQuery);
                      }
                      
                      return _buildSearchResults(results);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: Text('Error: $error'),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSearchHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Type to search for products',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'in ${widget.parentCategory.name}',
            style: TextStyle(
              color: widget.parentCategory.themeColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found for "$query"',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults(List<SubCategory> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final subCategory = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: subCategory.imageUrl ?? 'https://placehold.co/100/CCCCCC/FFFFFF?text=No+Image',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                ),
                errorWidget: (context, url, error) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.error, color: Colors.grey),
                ),
              ),
            ),
            title: Text(subCategory.name),
            subtitle: Text('${subCategory.productCount} products'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to product listing
              context.pop();
              context.go(
                '/category/${subCategory.id}',
                extra: {
                  'name': subCategory.name,
                  'parentCategory': widget.parentCategory.name,
                },
              );
            },
          ),
        );
      },
    );
  }
} 