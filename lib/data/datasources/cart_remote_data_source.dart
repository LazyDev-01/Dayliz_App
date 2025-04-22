import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../../core/constants/api.dart';
import '../../domain/entities/product.dart';

/// Exception thrown when a cart operation fails
class CartException implements Exception {
  final String message;

  CartException(this.message);

  @override
  String toString() => 'CartException: $message';
}

/// Interface for cart remote data source
abstract class CartRemoteDataSource {
  /// Get all cart items from the remote API
  /// Throws [CartException] if something goes wrong
  Future<List<CartItemModel>> getCartItems();

  /// Add a product to the cart using the remote API
  /// Throws [CartException] if something goes wrong
  Future<CartItemModel> addToCart({
    required Product product,
    required int quantity,
  });

  /// Remove an item from the cart using the remote API
  /// Throws [CartException] if something goes wrong
  Future<bool> removeFromCart({
    required String cartItemId,
  });

  /// Update the quantity of an item in the cart using the remote API
  /// Throws [CartException] if something goes wrong
  Future<CartItemModel> updateQuantity({
    required String cartItemId,
    required int quantity,
  });

  /// Clear the cart using the remote API
  /// Throws [CartException] if something goes wrong
  Future<bool> clearCart();

  /// Get the total price of all items in the cart
  /// Throws [CartException] if something goes wrong
  Future<double> getTotalPrice();

  /// Get the total number of items in the cart
  /// Throws [CartException] if something goes wrong
  Future<int> getItemCount();

  /// Check if a product is in the cart
  /// Throws [CartException] if something goes wrong
  Future<bool> isInCart({
    required String productId,
  });
}

/// Implementation of the cart remote data source
class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final http.Client client;

  CartRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CartItemModel>> getCartItems() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cartEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> cartItemsJson = jsonData['items'];
        
        return cartItemsJson
            .map((item) => CartItemModel.fromJson(item))
            .toList();
      } else {
        throw CartException('Failed to load cart items');
      }
    } catch (e) {
      throw CartException(e.toString());
    }
  }

  @override
  Future<CartItemModel> addToCart({
    required Product product,
    required int quantity,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cartEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.apiKey}',
        },
        body: json.encode({
          'product_id': product.id,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return CartItemModel.fromJson(jsonData);
      } else {
        throw CartException('Failed to add item to cart');
      }
    } catch (e) {
      throw CartException(e.toString());
    }
  }

  @override
  Future<bool> removeFromCart({
    required String cartItemId,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cartEndpoint}/$cartItemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw CartException('Failed to remove item from cart');
      }
    } catch (e) {
      throw CartException(e.toString());
    }
  }

  @override
  Future<CartItemModel> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      final response = await client.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cartEndpoint}/$cartItemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.apiKey}',
        },
        body: json.encode({
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CartItemModel.fromJson(jsonData);
      } else {
        throw CartException('Failed to update cart item quantity');
      }
    } catch (e) {
      throw CartException(e.toString());
    }
  }

  @override
  Future<bool> clearCart() async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cartEndpoint}/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw CartException('Failed to clear cart');
      }
    } catch (e) {
      throw CartException(e.toString());
    }
  }

  @override
  Future<double> getTotalPrice() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cartEndpoint}/total'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['total'].toDouble();
      } else {
        throw CartException('Failed to get cart total price');
      }
    } catch (e) {
      throw CartException(e.toString());
    }
  }

  @override
  Future<int> getItemCount() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cartEndpoint}/count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['count'];
      } else {
        throw CartException('Failed to get cart item count');
      }
    } catch (e) {
      throw CartException(e.toString());
    }
  }

  @override
  Future<bool> isInCart({
    required String productId,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cartEndpoint}/check/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.apiKey}',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['exists'];
      } else {
        throw CartException('Failed to check if product is in cart');
      }
    } catch (e) {
      throw CartException(e.toString());
    }
  }
} 