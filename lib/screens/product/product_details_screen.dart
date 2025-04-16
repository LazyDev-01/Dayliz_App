import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/cart_item.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/providers/cart_provider.dart';
import 'package:dayliz_app/widgets/rating_bar.dart';
import 'package:dayliz_app/providers/wishlist_provider.dart';
import 'package:dayliz_app/services/image_service.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  
  @override
  void initState() {
    super.initState();
    
    // Preload additional images if they exist
    _preloadImages();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _preloadImages() {
    final product = widget.product;
    
    // Preload main image with high quality
    precacheImage(
      CachedNetworkImageProvider(
        imageService.optimizeUrl(
          product.imageUrl,
          quality: 90,
        ),
      ),
      context,
    );
    
    // Preload additional images if available
    if (product.additionalImages != null) {
      for (final imageUrl in product.additionalImages!) {
        precacheImage(
          CachedNetworkImageProvider(
            imageService.optimizeUrl(
              imageUrl,
              quality: 80,
            ),
          ),
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isInWishlist = ref.watch(isInWishlistProvider(product.id));
    final cartNotifier = ref.watch(cartProvider.notifier);
    
    // Get screen width for optimizing image size
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              Navigator.of(context).pop();
            } catch (e) {
              // If pop fails, navigate to home as fallback
              context.go('/home');
            }
          },
        ),
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
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement sharing functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images with Carousel if there are additional images
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  // Image carousel
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: product.additionalImages != null 
                        ? 1 + product.additionalImages!.length 
                        : 1,
                    itemBuilder: (context, index) {
                      // For the first item, use the main image
                      final imageUrl = index == 0 
                          ? product.imageUrl 
                          : product.additionalImages![index - 1];
                          
                      return Hero(
                        tag: index == 0 
                            ? 'product_image_${product.id}' 
                            : 'product_image_${product.id}_$index',
                        child: imageService.getOptimizedImage(
                          imageUrl: imageUrl,
                          width: screenWidth,
                          height: screenWidth,
                          fit: BoxFit.cover,
                          // Higher quality for detail view
                          quality: 90,
                        ),
                      );
                    },
                  ),
                  
                  // Dots indicator for multiple images
                  if (product.additionalImages != null && product.additionalImages!.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          1 + (product.additionalImages?.length ?? 0),
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 12 : 8,
                            height: _currentImageIndex == index ? 12 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index 
                                  ? Theme.of(context).primaryColor 
                                  : Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
                        RatingBar(
                          rating: product.rating,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)",
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
                        '\$${product.discountedPrice.toStringAsFixed(2)}',
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
                            '${product.discountPercentage?.toInt()}% OFF',
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
              _addToCart();
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

  void _addToCart() {
    ref.read(cartProvider.notifier).addToCart(widget.product, quantity: _quantity);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            Navigator.of(context).pushNamed('/cart');
          },
        ),
      ),
    );
  }
} 