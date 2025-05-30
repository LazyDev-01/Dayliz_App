import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../../domain/entities/product.dart';

/// Exception thrown when a local cart operation fails
class CartLocalException implements Exception {
  final String message;

  CartLocalException(this.message);

  @override
  String toString() => 'CartLocalException: $message';
}

/// Interface for cart local data source
abstract class CartLocalDataSource {
  /// Get all cached cart items
  /// Throws [CartLocalException] if something goes wrong
  Future<List<CartItemModel>> getCachedCartItems();

  /// Cache cart items
  /// Throws [CartLocalException] if something goes wrong
  Future<bool> cacheCartItems(List<CartItemModel> cartItems);

  /// Add a product to the cached cart
  /// Throws [CartLocalException] if something goes wrong
  Future<CartItemModel> addToLocalCart({
    required Product product,
    required int quantity,
  });

  /// Remove an item from the cached cart
  /// Throws [CartLocalException] if something goes wrong
  Future<bool> removeFromLocalCart({
    required String cartItemId,
  });

  /// Update the quantity of an item in the cached cart
  /// Throws [CartLocalException] if something goes wrong
  Future<CartItemModel> updateLocalQuantity({
    required String cartItemId,
    required int quantity,
  });

  /// Clear the cached cart
  /// Throws [CartLocalException] if something goes wrong
  Future<bool> clearLocalCart();

  /// Get the total price of all items in the cached cart
  /// Throws [CartLocalException] if something goes wrong
  Future<double> getLocalTotalPrice();

  /// Get the total number of items in the cached cart
  /// Throws [CartLocalException] if something goes wrong
  Future<int> getLocalItemCount();

  /// Check if a product is in the cached cart
  /// Throws [CartLocalException] if something goes wrong
  Future<bool> isInLocalCart({
    required String productId,
  });
}

/// Implementation of the cart local data source
class CartLocalDataSourceImpl implements CartLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String _cachedCartKey = 'CACHED_CART';

  CartLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<CartItemModel>> getCachedCartItems() async {
    try {
      final jsonString = sharedPreferences.getString(_cachedCartKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((item) => CartItemModel.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      throw CartLocalException('Failed to get cached cart items: ${e.toString()}');
    }
  }

  @override
  Future<bool> cacheCartItems(List<CartItemModel> cartItems) async {
    try {
      final List<Map<String, dynamic>> jsonList = cartItems
          .map((item) => (item).toJson())
          .toList();
      
      return await sharedPreferences.setString(
        _cachedCartKey,
        json.encode(jsonList),
      );
    } catch (e) {
      throw CartLocalException('Failed to cache cart items: ${e.toString()}');
    }
  }

  @override
  Future<CartItemModel> addToLocalCart({
    required Product product,
    required int quantity,
  }) async {
    try {
      final currentItems = await getCachedCartItems();
      
      // Check if product already exists in cart
      final existingItemIndex = currentItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      
      if (existingItemIndex >= 0) {
        // Update quantity if product already exists
        final updatedItem = currentItems[existingItemIndex].copyWithModel(
          quantity: currentItems[existingItemIndex].quantity + quantity,
        );
        
        currentItems[existingItemIndex] = updatedItem;
        await cacheCartItems(currentItems);
        
        return updatedItem;
      } else {
        // Add new product to cart
        final newItem = CartItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product as ProductModel,
          quantity: quantity,
          addedAt: DateTime.now(),
        );
        
        currentItems.add(newItem);
        await cacheCartItems(currentItems);
        
        return newItem;
      }
    } catch (e) {
      throw CartLocalException('Failed to add to local cart: ${e.toString()}');
    }
  }

  @override
  Future<bool> removeFromLocalCart({
    required String cartItemId,
  }) async {
    try {
      final currentItems = await getCachedCartItems();
      
      final updatedItems = currentItems.where((item) => item.id != cartItemId).toList();
      
      if (currentItems.length == updatedItems.length) {
        return false; // Item not found
      }
      
      return await cacheCartItems(updatedItems);
    } catch (e) {
      throw CartLocalException('Failed to remove from local cart: ${e.toString()}');
    }
  }

  @override
  Future<CartItemModel> updateLocalQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      final currentItems = await getCachedCartItems();
      
      final itemIndex = currentItems.indexWhere((item) => item.id == cartItemId);
      
      if (itemIndex < 0) {
        throw CartLocalException('Cart item not found');
      }
      
      final updatedItem = currentItems[itemIndex].copyWithModel(
        quantity: quantity,
      );
      
      currentItems[itemIndex] = updatedItem;
      await cacheCartItems(currentItems);
      
      return updatedItem;
    } catch (e) {
      throw CartLocalException('Failed to update local quantity: ${e.toString()}');
    }
  }

  @override
  Future<bool> clearLocalCart() async {
    try {
      return await sharedPreferences.remove(_cachedCartKey);
    } catch (e) {
      throw CartLocalException('Failed to clear local cart: ${e.toString()}');
    }
  }

  @override
  Future<double> getLocalTotalPrice() async {
    try {
      final currentItems = await getCachedCartItems();
      
      return currentItems.fold<double>(0, (double total, item) => total + item.totalPrice);
    } catch (e) {
      throw CartLocalException('Failed to get local total price: ${e.toString()}');
    }
  }

  @override
  Future<int> getLocalItemCount() async {
    try {
      final currentItems = await getCachedCartItems();
      
      return currentItems.fold<int>(0, (int count, item) => count + item.quantity);
    } catch (e) {
      throw CartLocalException('Failed to get local item count: ${e.toString()}');
    }
  }

  @override
  Future<bool> isInLocalCart({
    required String productId,
  }) async {
    try {
      final currentItems = await getCachedCartItems();
      
      return currentItems.any((item) => item.product.id == productId);
    } catch (e) {
      throw CartLocalException('Failed to check if in local cart: ${e.toString()}');
    }
  }
} 