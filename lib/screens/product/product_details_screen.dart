import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/providers/cart_provider.dart';
import 'package:dayliz_app/widgets/rating_bar.dart';
import 'package:dayliz_app/providers/wishlist_provider.dart';

// Mock product provider - will be replaced with actual API calls
final selectedProductProvider = StateProvider<Map<String, dynamic>>((ref) => {
      'id': '101',
      'name': 'Classic Leather Jacket',
      'description':
          'Premium quality leather jacket with elegant design. Perfect for casual outings and special occasions. Features multiple pockets and soft inner lining for comfort.',
      'price': 129.99,
      'discountPercentage': 15,
      'rating': 4.7,
      'reviews': 28,
      'imageUrl': 'assets/images/products/jacket.jpg',
      'images': [
        'assets/images/products/jacket.jpg',
        'assets/images/products/jacket_2.jpg',
        'assets/images/products/jacket_3.jpg',
      ],
      'inStock': true,
      'category': 'Fashion',
      'subcategory': 'Outerwear',
    });

// Provider for wishlist to check if product is in wishlist
final isInWishlistProvider = StateProvider.family<bool, String>((ref, id) => false);

class ProductDetailsScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailsScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This would typically come from a product provider in a real app
    // For now we'll mock the product data
    final product = _getMockProduct();
    
    final isInWishlist = ref.watch(isInWishlistProvider(productId));
    final cartNotifier = ref.watch(cartProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: Icon(
              isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: isInWishlist ? Colors.red : null,
            ),
            onPressed: () {
              ref.read(wishlistProvider.notifier).toggleWishlistItem(
                WishlistItem(
                  id: product.id,
                  productId: product.id,
                  name: product.name,
                  price: product.price,
                  imageUrl: product.imageUrl,
                  dateAdded: DateTime.now(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _getImageProvider(product.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            // Product Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating
                  if (product.rating != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Price
                  Row(
                    children: [
                      if (product.hasDiscount) ...[
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '\$${(product.hasDiscount ? product.discountedPrice! : product.price).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.discountPercentage}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // Add to cart
              cartNotifier.addToCart(product);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} added to cart'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'VIEW CART',
                    onPressed: () {
                      // Navigate to cart screen
                      Navigator.of(context).pushNamed('/cart');
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Add to Cart'),
          ),
        ),
      ),
    );
  }
  
  // Mock function to get product details - in a real app, this would come from a provider
  Product _getMockProduct() {
    return Product(
      id: productId,
      name: 'Organic Bananas',
      description: 'Fresh organic bananas from local farms. These bananas are grown without pesticides and are hand-picked to ensure the best quality. Perfect for a healthy snack, smoothies, or as a topping for your morning cereal.',
      price: 4.99,
      discountedPrice: 3.99,
      imageUrl: 'assets/images/banana.jpg',
      isInStock: true,
      stockQuantity: 100,
      categories: ['Fruits', 'Organic'],
      rating: 4.5,
      reviewCount: 128,
      brand: 'Organic Farms',
      dateAdded: DateTime.now().subtract(const Duration(days: 10)),
      attributes: {
        'weight': '1kg',
        'origin': 'Ecuador',
        'organic': true,
      },
    );
  }
  
  double _calculateOriginalPrice(double currentPrice, double discountPercentage) {
    return currentPrice / (1 - (discountPercentage / 100));
  }
  
  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else {
      return AssetImage(imageUrl);
    }
  }
} 