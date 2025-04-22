import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/category.dart';
import '../../providers/clean_category_providers.dart';
import '../product/clean_subcategory_product_screen.dart';

class CleanSubcategoryScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const CleanSubcategoryScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  ConsumerState<CleanSubcategoryScreen> createState() => _CleanSubcategoryScreenState();
}

class _CleanSubcategoryScreenState extends ConsumerState<CleanSubcategoryScreen> {
  late String _displayName;
  bool _isLoading = true;
  String? _errorMessage;
  Category? _category;

  @override
  void initState() {
    super.initState();
    _displayName = widget.categoryName.isNotEmpty ? widget.categoryName : 'Category';
    
    // Load category data
    Future.microtask(() => _loadCategory());
  }

  Future<void> _loadCategory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load the category
      await ref.read(categoriesNotifierProvider.notifier).loadCategoryById(widget.categoryId);
      
      // Get the current state
      final state = ref.read(categoriesNotifierProvider);
      
      setState(() {
        _isLoading = false;
        _category = state.selectedCategory;
        
        // Update display name if needed
        if (_category != null && widget.categoryName.isEmpty) {
          _displayName = _category!.name;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load category: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the selected category for updates
    final categoriesState = ref.watch(categoriesNotifierProvider);
    
    // If we get a new selected category from the provider, update our local state
    if (categoriesState.selectedCategory != null && 
        categoriesState.selectedCategory?.id == widget.categoryId &&
        _category?.id != categoriesState.selectedCategory?.id) {
      _category = categoriesState.selectedCategory;
      if (widget.categoryName.isEmpty) {
        _displayName = _category!.name;
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_errorMessage != null) {
      return _buildErrorState(context, _errorMessage!);
    }

    // Category not found
    if (_category == null) {
      return _buildErrorState(context, 'Category not found');
    }
    
    // No subcategories
    if (_category!.subCategories == null || _category!.subCategories!.isEmpty) {
      return _buildEmptyState(context, 'No subcategories found for this category');
    }
    
    // Show subcategories list
    return _buildSubcategoriesList(context, _category!);
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCategory,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCategory,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoriesList(BuildContext context, Category category) {
    final subcategories = category.subCategories!;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final subcategory = subcategories[index];
        return _buildSubcategoryItem(context, category, subcategory);
      },
    );
  }

  Widget _buildSubcategoryItem(
    BuildContext context, 
    Category parentCategory, 
    SubCategory subcategory
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to subcategory products screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CleanSubcategoryProductScreen(
                subcategoryId: subcategory.id,
                subcategoryName: subcategory.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Subcategory image if available
              if (subcategory.imageUrl != null && subcategory.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    subcategory.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: parentCategory.themeColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: parentCategory.themeColor ?? Colors.blue,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: parentCategory.themeColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    _getIconFromName(subcategory.iconName),
                    color: parentCategory.themeColor ?? Colors.blue,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subcategory.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (subcategory.productCount != null && subcategory.productCount! > 0)
                      Text(
                        '${subcategory.productCount} products',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: parentCategory.themeColor ?? Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to convert subcategory icon names to IconData
  IconData _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.category;
    
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
} 