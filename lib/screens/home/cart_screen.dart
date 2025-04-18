import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/screens/checkout/checkout_screen.dart';
import 'package:dayliz_app/screens/cart_screen.dart' as main_cart;

// Mock cart data provider
final cartItemsProvider = StateProvider<List<CartItem>>((ref) {
  return [
    CartItem(
      id: '1',
      productId: '1',
      name: 'Fresh Tomatoes',
      price: 40.0,
      quantity: 2,
      imageUrl: 'https://placehold.co/100/FF5252/FFFFFF?text=Tomato',
    ),
    CartItem(
      id: '2',
      productId: '2',
      name: 'Onions (1 kg)',
      price: 30.0,
      quantity: 1,
      imageUrl: 'https://placehold.co/100/9C27B0/FFFFFF?text=Onion',
    ),
    CartItem(
      id: '3',
      productId: '3',
      name: 'Whole Wheat Bread',
      price: 35.0,
      quantity: 1,
      imageUrl: 'https://placehold.co/100/795548/FFFFFF?text=Bread',
    ),
    CartItem(
      id: '4',
      productId: '4',
      name: 'Milk (1 liter)',
      price: 65.0,
      quantity: 2,
      imageUrl: 'https://placehold.co/100/FFFFFF/000000?text=Milk',
    ),
  ];
});

class CartItem {
  final String id;
  final String productId;
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
    String? id,
    String? productId,
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
    // Simply render the main cart screen directly
    return const main_cart.CartScreen();
  }
} 