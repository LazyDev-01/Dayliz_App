import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_categories.dart';
import '../../../domain/entities/category.dart';
import '../../providers/cart_providers.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/common/common_bottom_nav_bar.dart';
import '../product/clean_product_listing_screen.dart';

class CleanCategoriesScreen extends ConsumerStatefulWidget {
  const CleanCategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanCategoriesScreen> createState() => _CleanCategoriesScreenState();
}

class _CleanCategoriesScreenState extends ConsumerState<CleanCategoriesScreen> {
  late List<CategorySection> _categorySections;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Load mock category sections
    _loadCategorySections();
  }

  Future<void> _loadCategorySections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Load mock data
      _categorySections = MockCategories.getCategorySections();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load categories: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch cart item count for badge
    final cartItemCount = ref.watch(cartItemCountProvider);

    // Set the current index for the bottom navigation bar
    ref.read(bottomNavIndexProvider.notifier).state = 1; // 1 is for Categories

    return Scaffold(
      appBar: CommonAppBars.simple(
        title: 'Categories',
        centerTitle: true,
        showShadow: false,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 1, // Categories tab
        cartItemCount: cartItemCount,
      ),
    );
  }

  Widget _buildBody() {
    // Show loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategorySections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (_categorySections.isEmpty) {
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
              onPressed: _loadCategorySections,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Show category sections with subcategories
    return RefreshIndicator(
      onRefresh: () async {
        await _loadCategorySections();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: _categorySections.length,
        itemBuilder: (context, index) {
          final section = _categorySections[index];
          return _buildCategorySection(context, section);
        },
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, CategorySection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Icon(
                section.icon,
                color: section.themeColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                section.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Subcategories grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
          ),
          itemCount: section.subcategories.length,
          itemBuilder: (context, index) {
            final subcategory = section.subcategories[index];
            return _buildSubcategoryCard(context, subcategory, section.themeColor);
          },
        ),

        // Add some spacing between sections
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubcategoryCard(BuildContext context, SubCategory subcategory, Color themeColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _navigateToSubcategoryProducts(subcategory),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Subcategory image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: subcategory.imageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          subcategory.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.category,
                              color: themeColor.withAlpha(150),
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.category,
                        color: themeColor.withAlpha(150),
                        size: 30,
                      ),
              ),
              const SizedBox(height: 8),
              // Subcategory name
              Text(
                subcategory.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubcategoryProducts(SubCategory subcategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CleanProductListingScreen(
          subcategoryId: subcategory.id,
        ),
        // Pass the subcategory name as an argument to be used in the title
        settings: RouteSettings(
          arguments: {
            'subcategoryName': subcategory.name,
          },
        ),
      ),
    );
  }
}