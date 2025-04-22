import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/product.dart';
import '../../providers/product_providers.dart';
import 'clean_product_details_screen.dart';

/// A simplified screen for testing clean architecture product features
/// This version avoids complex provider management to prevent errors
class ProductFeatureTestingScreen extends StatelessWidget {
  const ProductFeatureTestingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean Architecture Testing'),
      ),
      body: const _TestingScreenContent(),
    );
  }
}

/// Main content of the testing screen
class _TestingScreenContent extends StatelessWidget {
  const _TestingScreenContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Testing instructions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.amber.shade100,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clean Architecture Product Feature Testing',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This screen demonstrates the product features implemented using clean architecture principles. Select a testing option below:',
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTestCard(
                context: context,
                title: 'View Product Listing Screen',
                description: 'Display a list of products using the clean architecture implementation.',
                icon: Icons.list_alt,
                onTap: () => _navigateToProductListing(context),
              ),
              
              const SizedBox(height: 16),
              
              _buildTestCard(
                context: context,
                title: 'View Sample Product Details',
                description: 'Display details for a sample product using the clean architecture implementation.',
                icon: Icons.inventory_2,
                onTap: () => _navigateToSampleProductDetails(context),
              ),
              
              const SizedBox(height: 16),
              
              _buildTestCard(
                context: context,
                title: 'View Products by Category',
                description: 'Browse products filtered by category.',
                icon: Icons.category,
                onTap: () => _navigateToProductsByCategory(context),
              ),
              
              const SizedBox(height: 32),
              
              // Information section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Clean Architecture',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The clean architecture implementation separates the app into layers:'
                      '\n\n• Domain Layer: Contains business logic and entities'
                      '\n• Data Layer: Handles data retrieval and storage'
                      '\n• Presentation Layer: Manages UI and state',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build a card for each testing option
  Widget _buildTestCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Navigate to the products listing screen
  void _navigateToProductListing(BuildContext context) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => const StaticProductListingScreen(),
      ),
    );
  }
  
  /// Navigate to a sample product's details screen
  void _navigateToSampleProductDetails(BuildContext context) {
    // Try multiple product IDs in case some aren't available
    const fallbackProductIds = ['1', '2', '3']; 
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CleanProductDetailsScreen(productId: fallbackProductIds.first),
      ),
    );
  }
  
  /// Navigate to products by category
  void _navigateToProductsByCategory(BuildContext context) {
    // Sample category ID
    const sampleCategoryId = '1'; // Or any category ID that exists in your system
    
    Navigator.pushNamed(
      context,
      '/clean/category',
      arguments: sampleCategoryId,
    );
  }
}

/// A completely static product listing screen to avoid provider issues
class StaticProductListingScreen extends StatelessWidget {
  const StaticProductListingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create sample static products for demonstration
    final sampleProducts = [
      Product(
        id: '1',
        name: 'Organic Fresh Vegetables Bundle',
        description: 'A bundle of fresh, organic vegetables including carrots, tomatoes, and lettuce.',
        price: 399.99,
        discountPercentage: 15,
        rating: 4.5,
        reviewCount: 128,
        mainImageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        inStock: true,
        categoryId: '1',
      ),
      Product(
        id: '2',
        name: 'Fresh Fruits Basket',
        description: 'Assorted fresh fruits including apples, oranges, and bananas.',
        price: 499.99,
        discountPercentage: 0,
        rating: 4.8,
        reviewCount: 95,
        mainImageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        inStock: true,
        categoryId: '1',
      ),
      Product(
        id: '3',
        name: 'Organic Apples (1kg)',
        description: 'Sweet and crispy organic apples.',
        price: 149.99,
        discountPercentage: 10,
        rating: 4.7,
        reviewCount: 110,
        mainImageUrl: 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        inStock: true,
        categoryId: '1',
      ),
      Product(
        id: '4',
        name: 'Fresh Berries Mix',
        description: 'A mix of fresh berries including strawberries, blueberries, and raspberries.',
        price: 349.99,
        discountPercentage: 5,
        rating: 4.9,
        reviewCount: 85,
        mainImageUrl: 'https://images.unsplash.com/photo-1563746924237-f4351c246054?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
        inStock: true,
        categoryId: '1',
      ),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Listing (Static Demo)'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: sampleProducts.length,
        itemBuilder: (context, index) {
          final product = sampleProducts[index];
          return _SimpleProductCard(
            product: product,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CleanProductDetailsScreen(
                  productId: product.id,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A simple product card for the testing screen
class _SimpleProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  
  const _SimpleProductCard({
    required this.product,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(product.mainImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: product.discountPercentage != null && product.discountPercentage! > 0
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.red,
                          child: Text(
                            '${product.discountPercentage!.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹${product.discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.discountPercentage != null && product.discountPercentage! > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '₹${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}