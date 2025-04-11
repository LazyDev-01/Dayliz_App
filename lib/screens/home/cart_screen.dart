import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/screens/checkout/checkout_screen.dart';

// Mock cart data provider
final cartItemsProvider = StateProvider<List<CartItem>>((ref) {
  return [
    CartItem(
      id: 1,
      productId: 1,
      name: 'Fresh Tomatoes',
      price: 40.0,
      quantity: 2,
      imageUrl: 'https://placehold.co/100/FF5252/FFFFFF?text=Tomato',
    ),
    CartItem(
      id: 2,
      productId: 2,
      name: 'Onions (1 kg)',
      price: 30.0,
      quantity: 1,
      imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Onion',
    ),
    CartItem(
      id: 3,
      productId: 3,
      name: 'Whole Wheat Bread',
      price: 35.0,
      quantity: 1,
      imageUrl: 'https://placehold.co/100/795548/FFFFFF?text=Bread',
    ),
    CartItem(
      id: 4,
      productId: 4,
      name: 'Milk (1 liter)',
      price: 65.0,
      quantity: 2,
      imageUrl: 'https://placehold.co/100/FFFFFF/000000?text=Milk',
    ),
  ];
});

class CartItem {
  final int id;
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  CartItem copyWith({
    int? id,
    int? productId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class CartScreen extends ConsumerWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartItemsProvider);
    
    // Calculate cart total
    final cartTotal = cartItems.fold<double>(
      0,
      (previousValue, item) => previousValue + (item.price * item.quantity),
    );
    
    // Calculate delivery fee
    final deliveryFee = cartTotal > 200 ? 0.0 : 40.0;
    
    // Calculate taxes (5% of subtotal)
    final taxes = cartTotal * 0.05;
    
    // Calculate order total
    final orderTotal = cartTotal + deliveryFee + taxes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _showClearCartDialog(context, ref);
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : _buildCartItems(context, ref, cartItems),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : _buildCheckoutBar(
              context,
              ref,
              cartTotal: cartTotal,
              deliveryFee: deliveryFee,
              taxes: taxes,
              orderTotal: orderTotal,
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to your cart to start shopping',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to home screen
              // In a real app, you would use a navigation method here
              // For now, we'll just use the bottom navigation
            },
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(
    BuildContext context,
    WidgetRef ref,
    List<CartItem> cartItems,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cartItems.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return _buildCartItemTile(context, ref, item);
      },
    );
  }

  Widget _buildCartItemTile(
    BuildContext context,
    WidgetRef ref,
    CartItem item,
  ) {
    return Dismissible(
      key: Key('cart_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _removeFromCart(ref, item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from cart'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                _addToCart(ref, item);
              },
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 70,
                height: 70,
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
            const SizedBox(width: 16),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      if (item.quantity > 1) {
                        _updateCartItemQuantity(ref, item, item.quantity - 1);
                      } else {
                        _showRemoveItemDialog(context, ref, item);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.remove,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _updateCartItemQuantity(ref, item, item.quantity + 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
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

  Widget _buildCheckoutBar(
    BuildContext context,
    WidgetRef ref, {
    required double cartTotal,
    required double deliveryFee,
    required double taxes,
    required double orderTotal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Item Total'),
              Text('₹${cartTotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Fee'),
              deliveryFee > 0
                  ? Text('₹${deliveryFee.toStringAsFixed(2)}')
                  : const Text(
                      'FREE',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Taxes'),
              Text('₹${taxes.toStringAsFixed(2)}'),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'To Pay',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '₹${orderTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _navigateToCheckout(context, ref);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateCartItemQuantity(WidgetRef ref, CartItem item, int newQuantity) {
    final cartItems = ref.read(cartItemsProvider);
    final updatedCartItems = cartItems.map((cartItem) {
      if (cartItem.id == item.id) {
        return cartItem.copyWith(quantity: newQuantity);
      }
      return cartItem;
    }).toList();
    
    ref.read(cartItemsProvider.notifier).state = updatedCartItems;
  }

  void _removeFromCart(WidgetRef ref, CartItem item) {
    final cartItems = ref.read(cartItemsProvider);
    final updatedCartItems = cartItems.where((cartItem) => cartItem.id != item.id).toList();
    
    ref.read(cartItemsProvider.notifier).state = updatedCartItems;
  }

  void _addToCart(WidgetRef ref, CartItem item) {
    final cartItems = ref.read(cartItemsProvider);
    final updatedCartItems = [...cartItems, item];
    
    ref.read(cartItemsProvider.notifier).state = updatedCartItems;
  }

  void _clearCart(WidgetRef ref) {
    ref.read(cartItemsProvider.notifier).state = [];
  }

  void _showRemoveItemDialog(BuildContext context, WidgetRef ref, CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${item.name} from your cart?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              _removeFromCart(ref, item);
              Navigator.of(context).pop();
            },
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear your cart?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              _clearCart(ref);
              Navigator.of(context).pop();
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  void _navigateToCheckout(BuildContext context, WidgetRef ref) {
    context.go('/checkout');
  }
} 