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
import 'package:dayliz_app/widgets/product/product_image_carousel.dart';
import 'package:dayliz_app/widgets/product/product_price_display.dart';

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
  
  @override
  void initState() {
    super.initState();
    
    // Schedule preloading after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _preloadImages();
      }
    });
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
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              // First try to check if we can go back via Navigator
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // If we can't pop, navigate directly to home
                context.go('/home');
              }
            } catch (e) {
              // If anything fails, use go_router as fallback
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
            onPressed: () => _toggleWishlist(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement sharing functionality
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Images with Carousel
                ProductImageCarousel(
                  mainImageUrl: product.imageUrl,
                  additionalImages: product.additionalImages,
                  productId: product.id,
                  width: availableWidth,
                  height: availableWidth,
                  quality: 90,
                ),
                
                // Product Info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductTitle(product),
                      const SizedBox(height: 8),
                      
                      // Rating
                      if (product.rating != null)
                        _buildRatingBar(product),
                      
                      const SizedBox(height: 16),
                      
                      // Price
                      ProductPriceDisplay(
                        price: product.price,
                        discountedPrice: product.discountedPrice,
                        discountPercentage: product.discountPercentage?.toInt(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Description
                      _buildDescriptionSection(product),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
      bottomNavigationBar: _buildBottomAddToCartButton(),
    );
  }
  
  Widget _buildProductTitle(Product product) {
    return Text(
      product.name,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
  
  Widget _buildRatingBar(Product product) {
    return Row(
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
    );
  }
  
  Widget _buildDescriptionSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
  
  Widget _buildBottomAddToCartButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _addToCart,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Add to Cart'),
        ),
      ),
    );
  }
  
  void _toggleWishlist() {
    ref.read(wishlistProvider.notifier).toggleWishlistItem(
      WishlistItem(
        id: widget.product.id,
        productId: widget.product.id,
        name: widget.product.name,
        price: widget.product.price,
        imageUrl: widget.product.imageUrl,
        dateAdded: DateTime.now(),
      ),
    );
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