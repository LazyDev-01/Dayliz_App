import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/cart_item.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _loadCartFromStorage();
  }

  // Load cart from SharedPreferences
  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartDataString = prefs.getString('cart_data');
      
      if (cartDataString != null) {
        final List<dynamic> cartData = jsonDecode(cartDataString);
        state = cartData.map((item) => CartItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading cart data: $e');
    }
  }

  // Save cart to SharedPreferences
  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartDataString = jsonEncode(state.map((item) => item.toJson()).toList());
      await prefs.setString('cart_data', cartDataString);
    } catch (e) {
      print('Error saving cart data: $e');
    }
  }

  // Add a product to the cart
  void addToCart(Product product, {int quantity = 1}) {
    final existingItemIndex = state.indexWhere((item) => item.productId == product.id);
    
    if (existingItemIndex >= 0) {
      // Update existing item
      final existingItem = state[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      
      final updatedCart = [...state];
      updatedCart[existingItemIndex] = updatedItem;
      
      state = updatedCart;
    } else {
      // Add new item
      final newItem = CartItem.fromProduct(product, quantity: quantity);
      state = [...state, newItem];
    }
    
    _saveCartToStorage();
  }

  // Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    
    state = state.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    
    _saveCartToStorage();
  }

  // Remove an item from the cart
  void removeFromCart(String productId) {
    state = state.where((item) => item.productId != productId).toList();
    _saveCartToStorage();
  }

  // Clear the entire cart
  void clearCart() {
    state = [];
    _saveCartToStorage();
  }

  // Get cart total - renamed to totalAmount to match usage in cart_screen.dart
  double get totalAmount {
    return state.fold(0, (sum, item) => sum + item.total);
  }
  
  // Get original total getter for backward compatibility
  double get total => totalAmount;

  // Get total number of items
  int get itemCount {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
}); 