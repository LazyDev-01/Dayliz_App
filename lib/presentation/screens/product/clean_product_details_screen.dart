import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/product.dart';
import '../../providers/product_providers.dart';
import '../../providers/cart_providers.dart';
import '../../providers/wishlist_providers.dart';

class CleanProductDetailsScreen extends ConsumerWidget {
  final String productId;
  
  const CleanProductDetailsScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the product state
    final productState = ref.watch(productByIdNotifierProvider(productId));
    
    // Watch related products state
    final relatedProductsState = ref.watch(relatedProductsNotifierProvider(productId));
    
    // Watch if product is in cart
    final isInCartFuture = ref.watch(isProductInCartProvider(productId));
    
    // Watch if product is in wishlist
    final isInWishlistFuture = ref.watch(isProductInWishlistProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: Text(productState.product?.name ?? 'Product Details'),
        actions: [
          // Wishlist button
          Consumer(
            builder: (context, ref, child) {
              final isInWishlist = ref.watch(isProductInWishlistProvider(productId));
              
              return isInWishlist.when(
                data: (isInWishlist) => IconButton(
                  icon: Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? Colors.red : null,
                  ),
                  onPressed: () => _toggleWishlist(context, ref),
                  tooltip: isInWishlist ? 'Remove from wishlist' : 'Add to wishlist',
                ),
                loading: () => const IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: null,
                ),
                error: (_, __) => IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () => _toggleWishlist(context, ref),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share product functionality
            },
          ),
        ],
      ),
      body: _buildBody(context, ref, productState, relatedProductsState, isInCartFuture),
    );
  }

  void _toggleWishlist(BuildContext context, WidgetRef ref) async {
    final product = ref.read(productByIdNotifierProvider(productId)).product;
    if (product == null) return;
    
    final isInWishlist = await ref.read(wishlistNotifierProvider.notifier).isInWishlist(productId);
    
    if (isInWishlist) {
      await ref.read(wishlistNotifierProvider.notifier).removeFromWishlist(productId);
      _showSnackBar(context, '${product.name} removed from wishlist');
    } else {
      await ref.read(wishlistNotifierProvider.notifier).addToWishlist(productId);
      _showSnackBar(context, '${product.name} added to wishlist');
    }
  }
  
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Wishlist',
          onPressed: () => context.push('/clean-wishlist'),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, 
    WidgetRef ref,
    ProductState productState, 
    RelatedProductsState relatedProductsState,
    AsyncValue<bool> isInCartFuture
  ) {
    // Show loading state
    if (productState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (productState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${productState.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(productByIdNotifierProvider(productId).notifier).getProduct();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state if product is null
    final product = productState.product;
    if (product == null) {
      return const Center(child: Text('Product not found'));
    }

    // Build the product details UI
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            height: 300,
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
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.discountPercentage!.toInt()}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          
          // Product information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                
                const SizedBox(height: 8),
                
                // Price
                Row(
                  children: [
                    Text(
                      '₹${product.discountedPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    if (product.discountPercentage != null && product.discountPercentage! > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      product.rating?.toStringAsFixed(1) ?? 'No ratings',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (product.reviewCount != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${product.reviewCount} reviews)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 24),
                
                // Add to cart button
                SizedBox(
                  width: double.infinity,
                  child: isInCartFuture.when(
                    data: (isInCart) {
                      return ElevatedButton(
                        onPressed: () => _handleAddToCart(context, ref, product, isInCart),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(isInCart ? 'Go to Cart' : 'Add to Cart'),
                      );
                    },
                    loading: () => ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                    error: (_, __) => ElevatedButton(
                      onPressed: () => _handleAddToCart(context, ref, product, false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ),
                
                // Wishlist & Share buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => _toggleWishlist(context, ref),
                      icon: Consumer(
                        builder: (context, ref, child) {
                          final isInWishlist = ref.watch(isProductInWishlistProvider(productId));
                          return isInWishlist.when(
                            data: (isInWishlist) => Icon(
                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                              color: isInWishlist ? Colors.red : null,
                            ),
                            loading: () => const Icon(Icons.favorite_border),
                            error: (_, __) => const Icon(Icons.favorite_border),
                          );
                        },
                      ),
                      label: const Text('Wishlist'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Share product functionality
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Related products
          if (relatedProductsState.products.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16).copyWith(bottom: 8),
              child: Text(
                'You may also like',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: relatedProductsState.products.length,
                itemBuilder: (context, index) {
                  return _buildRelatedProductCard(
                    context, 
                    relatedProductsState.products[index],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  void _handleAddToCart(BuildContext context, WidgetRef ref, Product product, bool isInCart) {
    if (isInCart) {
      // Navigate to cart screen
      context.push('/cart');
    } else {
      // Add to cart
      ref.read(cartNotifierProvider.notifier).addToCart(
        product: product,
        quantity: 1,
      );

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () => context.push('/cart'),
          ),
        ),
      );
    }
  }

  Widget _buildRelatedProductCard(BuildContext context, Product product) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to the product details
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(
                builder: (context) => CleanProductDetailsScreen(productId: product.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(product.mainImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              
              // Product info
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Price
                    Text(
                      '₹${product.discountedPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 