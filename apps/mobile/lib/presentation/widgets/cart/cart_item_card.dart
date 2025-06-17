import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/cart_item.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;

  const CartItemCard({
    Key? key,
    required this.cartItem,
    required this.onRemove,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = cartItem.product;
    final quantity = cartItem.quantity;
    final totalPrice = cartItem.totalPrice;

    return Dismissible(
      key: Key(cartItem.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 26,
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.mainImageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Product weight/unit display
                    if (_getWeightDisplay(product).isNotEmpty) ...[
                      Text(
                        _getWeightDisplay(product),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Price display
                    if (product.discountPercentage != null && product.discountPercentage! > 0) ...[
                      Row(
                        children: [
                          Text(
                            '₹${product.discountedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        '₹${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Total price
                    Text(
                      'Total: \$${totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity Controls
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onPressed: () => onQuantityChanged(quantity - 1),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          onPressed: () => onQuantityChanged(quantity + 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  /// Get weight/unit display text from product attributes
  String _getWeightDisplay(product) {
    if (product.attributes == null) return '';

    // Try different possible keys for weight/unit information
    final weight = product.attributes!['weight']?.toString();
    final unit = product.attributes!['unit']?.toString();
    final quantity = product.attributes!['quantity']?.toString();
    final volume = product.attributes!['volume']?.toString();

    if (weight != null && weight.isNotEmpty) return weight;
    if (unit != null && unit.isNotEmpty) return unit;
    if (quantity != null && quantity.isNotEmpty) return quantity;
    if (volume != null && volume.isNotEmpty) return volume;

    return '';
  }
}