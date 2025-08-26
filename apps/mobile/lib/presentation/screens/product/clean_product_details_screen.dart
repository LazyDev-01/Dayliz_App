import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/entities/cart_item.dart';
import '../../providers/product_detail_providers.dart';
import '../../providers/cart_providers.dart';

import '../../widgets/auth/auth_guard.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/product/standard_product_card.dart';

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

    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: productState.product?.name ?? 'Product Details',
        fallbackRoute: '/home',
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF374151)),
            onPressed: () => _shareProduct(context, productState.product),
            tooltip: 'Share',
          ),
        ],
      ),
      body: _buildBody(context, ref, productState, relatedProductsState, isInCartFuture),
      bottomNavigationBar: _buildBottomAddToCart(context, ref, productState.product, isInCartFuture),
    );
  }



  void _shareProduct(BuildContext context, Product? product) {
    if (product == null) return;

    // Enhanced share functionality
    final shareText = '''
🛒 Check out this amazing product!

${product.name}
💰 ₹${product.discountedPrice.toStringAsFixed(0)}${product.discountPercentage != null && product.discountPercentage! > 0 ? ' (${product.discountPercentage!.round()}% OFF)' : ''}

Download Dayliz App for the best grocery deals!
''';

    // For now, just show a snackbar. In production, you'd use share_plus package
    _showSnackBar(context, 'Share functionality - Product: ${product.name}');
    debugPrint('Share text: $shareText');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
                ref.read(productByIdNotifierProvider(productId).notifier).getProduct(productId);
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

    // Build the product details UI with modern design
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), // Smooth scrolling
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Product image with hero animation and performance optimization
          RepaintBoundary(
            child: Hero(
              tag: 'product-${product.id}',
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4, // Responsive height
              width: double.infinity,
              decoration: BoxDecoration(
                // No rounded corners but keep shadow effect
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.zero, // No rounded corners
                child: Stack(
                  children: [
                    // Product image with loading and error states
                    Image.network(
                      product.mainImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),

                    // Enhanced discount badge
                    if (product.discountPercentage != null && product.discountPercentage! > 0)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.redAccent],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${product.discountPercentage!.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    // Stock status indicator
                    if (!product.inStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          ),

          // Product information (no separate container)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name with enhanced typography
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // Enhanced price section with better visual hierarchy
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Current price
                    Text(
                      '₹${product.discountedPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800], // Changed from primaryColor to dark grey
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Original price if discounted
                    if (product.discountPercentage != null && product.discountPercentage! > 0) ...[
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Savings amount
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          'Save ₹${(product.price - product.discountedPrice).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // Stock status indicator with low stock warning
                if (!product.inStock)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else if (product.inStock &&
                         product.stockQuantity != null &&
                         product.stockQuantity! > 0 &&
                         product.stockQuantity! < 5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Only ${product.stockQuantity} left in stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Product Details Section (only shown if data is available)
                _buildProductDetailsSection(context, product),

                // Dynamic spacing - only add space if Product Details section was shown
                if (_hasDescription(product) || _hasSpecifications(product) || _hasNutritionalInfo(product))
                  const SizedBox(height: 24),

                // Seller Information Section
                _buildSellerInfoSection(context, product),

                const SizedBox(height: 40), // Increased spacing

                // Similar Products Section
                _buildSimilarProductsSection(context, ref, relatedProductsState),

                // Add to cart moved to bottom navigation bar
              ],
            ),
          ),

          // Bottom padding to account for fixed bottom bar
          const SizedBox(height: 100),

          // Related products section removed as requested
        ],
      ),
    );
  }

  /// Builds the bottom navigation bar with add to cart functionality
  Widget? _buildBottomAddToCart(BuildContext context, WidgetRef ref, Product? product, AsyncValue<bool> isInCartFuture) {
    if (product == null) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildAddToCartSection(context, ref, product),
      ),
    );
  }

  /// Builds the add to cart section with smooth quantity controls
  Widget _buildAddToCartSection(BuildContext context, WidgetRef ref, Product product) {
    return Consumer(
      builder: (context, ref, child) {
        // Watch cart items to get current quantity
        final cartItems = ref.watch(cartItemsProvider);
        final cartItem = cartItems.where((item) => item.product.id == product.id).firstOrNull;
        final currentQuantity = cartItem?.quantity ?? 0;
        final isInCart = currentQuantity > 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Row(
            children: [
              // Quantity controls (shown when item is in cart)
              if (isInCart) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _buildQuantityControls(context, ref, product, cartItem!, currentQuantity),
                ),
                const SizedBox(width: 12),
              ],

              // Add to cart button (expands to fill remaining space)
              Expanded(
                child: _buildAddToCartButton(context, ref, product, isInCart),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the quantity controls widget
  Widget _buildQuantityControls(BuildContext context, WidgetRef ref, Product product, CartItem cartItem, int quantity) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _updateQuantity(context, ref, cartItem, quantity - 1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 36,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
              ),
            ),
          ),

          // Quantity display
          Container(
            width: 46,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          // Increase button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _updateQuantity(context, ref, cartItem, quantity + 1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: 36,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the add to cart button
  Widget _buildAddToCartButton(BuildContext context, WidgetRef ref, Product product, bool isInCart) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: product.inStock
            ? () => _handleAddToCart(context, ref, product, isInCart)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isInCart
              ? Colors.green
              : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              product.inStock
                  ? (isInCart ? 'Go to Cart' : 'Add to Cart')
                  : 'Out of Stock',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Updates the quantity of an item in the cart
  void _updateQuantity(BuildContext context, WidgetRef ref, CartItem cartItem, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        // Remove from cart
        await ref.read(cartNotifierProvider.notifier).removeFromCart(
          cartItemId: cartItem.id,
        );
        debugPrint('${cartItem.product.name} removed from cart');
      } else {
        // Update quantity
        await ref.read(cartNotifierProvider.notifier).updateQuantity(
          cartItemId: cartItem.id,
          quantity: newQuantity,
        );
        debugPrint('${cartItem.product.name} quantity updated to $newQuantity');
      }
    } catch (e) {
      debugPrint('Failed to update quantity: $e');
      if (context.mounted) {
        _showSnackBar(context, 'Failed to update quantity');
      }
    }
  }

  void _handleAddToCart(BuildContext context, WidgetRef ref, Product product, bool isInCart) {
    if (isInCart) {
      // CART PROTECTION: Check auth before viewing cart
      final isAllowed = AuthGuardService.checkAuthAndPrompt(
        context: context,
        ref: ref,
        action: 'view_cart',
        onAuthRequired: () {
          debugPrint('🔒 CART PROTECTION: Guest user tried to view cart');
        },
      );

      if (isAllowed) {
        // Navigate to cart screen
        context.push('/clean/cart');
      }
    } else {
      // CART PROTECTION: Check auth before adding to cart
      final isAllowed = AuthGuardService.checkAuthAndPrompt(
        context: context,
        ref: ref,
        action: 'add_to_cart',
        onAuthRequired: () {
          debugPrint('🔒 CART PROTECTION: Guest user tried to add ${product.name} to cart');
        },
      );

      if (isAllowed) {
        // Add to cart
        ref.read(cartNotifierProvider.notifier).addToCart(
          product: product,
          quantity: 1,
        );

        // Success feedback disabled for early launch
        debugPrint('${product.name} added to cart');
      }
    }
  }



  /// Builds the Product Details section with Description, Specifications, and Nutritional Information
  /// Only shows sections that have data available
  Widget _buildProductDetailsSection(BuildContext context, Product product) {
    // Check if any section has data
    final hasDescription = _hasDescription(product);
    final hasSpecifications = _hasSpecifications(product);
    final hasNutritionalInfo = _hasNutritionalInfo(product);

    // If no data is available for any section, don't show the Product Details section at all
    if (!hasDescription && !hasSpecifications && !hasNutritionalInfo) {
      return const SizedBox.shrink();
    }

    // Build list of sections that have data
    final sections = <Widget>[];

    if (hasDescription) {
      sections.add(_buildDescriptionSection(context, product));
    }

    if (hasSpecifications) {
      if (sections.isNotEmpty) sections.add(const SizedBox(height: 20));
      sections.add(_buildSpecificationsSection(context, product));
    }

    if (hasNutritionalInfo) {
      if (sections.isNotEmpty) sections.add(const SizedBox(height: 20));
      sections.add(_buildNutritionalInfoSection(context, product));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title outside the container
        Text(
          'Product Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        // Container with rounded corners and box shadow
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections,
          ),
        ),
      ],
    );
  }

  /// Builds the Description section using real product data
  Widget _buildDescriptionSection(BuildContext context, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Builds the Specifications section using real attributes data
  Widget _buildSpecificationsSection(BuildContext context, Product product) {
    final specificationsData = _getSpecificationsData(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specifications',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        _buildExcelTable(specificationsData),
      ],
    );
  }

  /// Builds the Nutritional Information section using real nutritional data
  Widget _buildNutritionalInfoSection(BuildContext context, Product product) {
    final nutritionalData = _getNutritionalData(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutritional Info',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        _buildExcelTable(nutritionalData),
      ],
    );
  }

  /// Builds an Excel-like table with borders and proper formatting
  Widget _buildExcelTable(List<List<String>> data) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2), // Label column slightly wider
          1: FlexColumnWidth(1.8), // Value column
        },
        children: data.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isLastRow = index == data.length - 1;

          return TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: isLastRow
                    ? BorderSide.none
                    : BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
            children: [
              _buildExcelTableCell(row[0], isLabel: true),
              _buildExcelTableCell(row[1], isLabel: false),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Builds a table cell for the Excel-like table
  Widget _buildExcelTableCell(String text, {required bool isLabel}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          right: isLabel
              ? BorderSide(color: Colors.grey[300]!, width: 0.5)
              : BorderSide.none,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isLabel ? FontWeight.w600 : FontWeight.w500,
          color: isLabel ? Colors.grey[700] : Colors.grey[800],
        ),
      ),
    );
  }

  /// Helper methods to check if sections have data
  bool _hasDescription(Product product) {
    return product.description.isNotEmpty;
  }

  bool _hasSpecifications(Product product) {
    return product.attributes != null &&
           product.attributes!.isNotEmpty &&
           product.attributes!.values.any((value) =>
             value != null && value.toString().trim().isNotEmpty);
  }

  bool _hasNutritionalInfo(Product product) {
    return product.nutritionalInfo != null &&
           product.nutritionalInfo!.isNotEmpty &&
           product.nutritionalInfo!.values.any((value) =>
             value != null && value.toString().trim().isNotEmpty);
  }

  /// Helper method to get specifications data from attributes
  List<List<String>> _getSpecificationsData(Product product) {
    final data = <List<String>>[];

    if (product.attributes != null && product.attributes!.isNotEmpty) {
      // Define common specification keys and their display names
      final specKeys = {
        'weight': 'Weight',
        'volume': 'Volume',
        'quantity': 'Quantity',
        'brand': 'Brand',
        'manufacturer': 'Manufacturer',
        'dimension': 'Dimension',
        'size': 'Size',
        'color': 'Color',
        'material': 'Material',
        'origin': 'Origin',
        'shelf_life': 'Shelf Life',
        'storage': 'Storage',
      };

      // Add available specifications
      for (final entry in product.attributes!.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        if (value != null && value.toString().trim().isNotEmpty) {
          final displayName = specKeys[key] ?? _formatKey(key);
          data.add([displayName, value.toString()]);
        }
      }

      // Add vendor information if available
      if (product.vendorName != null && product.vendorName!.isNotEmpty) {
        data.add(['Brand', product.vendorName!]);
      }
    }

    return data;
  }

  /// Helper method to get nutritional data from nutritionalInfo
  List<List<String>> _getNutritionalData(Product product) {
    final data = <List<String>>[];

    if (product.nutritionalInfo != null && product.nutritionalInfo!.isNotEmpty) {
      // Define common nutritional keys and their display names
      final nutritionKeys = {
        'calories': 'Calories',
        'energy': 'Energy',
        'protein': 'Protein',
        'fat': 'Fat',
        'carbohydrates': 'Carbohydrates',
        'sugar': 'Sugar',
        'fiber': 'Fiber',
        'sodium': 'Sodium',
        'cholesterol': 'Cholesterol',
        'vitamin_a': 'Vitamin A',
        'vitamin_c': 'Vitamin C',
        'calcium': 'Calcium',
        'iron': 'Iron',
      };

      // Add available nutritional information
      for (final entry in product.nutritionalInfo!.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        if (value != null && value.toString().trim().isNotEmpty) {
          final displayName = nutritionKeys[key] ?? _formatKey(key);
          data.add([displayName, value.toString()]);
        }
      }
    }

    return data;
  }

  /// Helper method to format keys for display
  String _formatKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Builds the seller information section
  Widget _buildSellerInfoSection(BuildContext context, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title outside the container
        Text(
          'Seller Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        // Container with seller details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

          // Seller details
          _buildSellerInfoRow(
            context,
            'Seller Name',
            product.vendorName ?? 'Dayliz Fresh',
            Icons.business,
          ),
          const SizedBox(height: 8),

          _buildSellerInfoRow(
            context,
            'FSSAI License',
            product.vendorFssaiLicense ?? 'FSSAI-12345678901234',
            Icons.verified_outlined,
          ),
          const SizedBox(height: 8),

          _buildSellerInfoRow(
            context,
            'Address',
            product.vendorAddress ?? 'Tura, Meghalaya, India',
            Icons.location_on_outlined,
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),

          _buildSellerInfoRow(
            context,
            'Customer Support',
            'support@dayliz.in',
            Icons.support_agent_outlined,
          ),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper method to build seller info rows
  Widget _buildSellerInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the similar products section
  Widget _buildSimilarProductsSection(BuildContext context, WidgetRef ref, RelatedProductsState relatedProductsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'You might also like',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Products content
        if (relatedProductsState.isLoading)
          _buildSimilarProductsLoading()
        else if (relatedProductsState.errorMessage != null)
          _buildSimilarProductsError(context, ref)
        else if (relatedProductsState.products.isEmpty)
          _buildNoSimilarProducts()
        else
          _buildSimilarProductsList(context, relatedProductsState.products),
      ],
    );
  }

  /// Builds loading state for similar products
  Widget _buildSimilarProductsLoading() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds error state for similar products
  Widget _buildSimilarProductsError(BuildContext context, WidgetRef ref) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Failed to load similar products',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(relatedProductsNotifierProvider(productId).notifier)
                  .getRelatedProducts(productId);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds no similar products state
  Widget _buildNoSimilarProducts() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(
        'No similar products found',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  /// Builds the horizontal list of similar products
  Widget _buildSimilarProductsList(BuildContext context, List<Product> products) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final product = products[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StandardProductCard(
              product: product,
              width: 120, // Compact width for similar products
            ),
          );
        },
      ),
    );
  }


}