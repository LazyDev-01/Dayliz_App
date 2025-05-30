import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'cart_remote_data_source.dart';

/// Implementation of [CartRemoteDataSource] for Supabase backend
class CartSupabaseDataSource implements CartRemoteDataSource {
  final SupabaseClient _supabaseClient;
  final uuid = const Uuid();

  CartSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient {
    debugPrint('CartSupabaseDataSource initialized with client: $_supabaseClient');
  }

  @override
  Future<List<CartItemModel>> getCartItems() async {
    try {
      // Check authentication
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw ServerException(message: 'User is not authenticated');
      }

      // Fetch cart items with product details using join
      final response = await _supabaseClient
          .from('cart_items')
          .select('''
            id,
            product_id,
            quantity,
            added_at,
            selected,
            saved_for_later,
            products (
              id,
              name,
              description,
              price,
              sale_price,
              image_url,
              stock,
              brand,
              category_id,
              is_featured,
              is_active,
              created_at,
              updated_at,
              in_stock,
              average_rating,
              review_count
            )
          ''')
          .eq('user_id', user.id)
          .order('added_at', ascending: false);

      return (response as List<dynamic>).map((item) {
        // Convert to CartItemModel
        final product = ProductModel.fromJson(Map<String, dynamic>.from(item['products']));

        return CartItemModel(
          id: item['id'],
          product: product,
          quantity: item['quantity'],
          addedAt: DateTime.parse(item['added_at']),
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Failed to fetch cart items: ${e.toString()}');
    }
  }

  @override
  Future<CartItemModel> addToCart({
    required Product product,
    required int quantity,
  }) async {
    try {
      // Check authentication
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        // For testing purposes, use a mock user ID
        debugPrint('CartSupabaseDataSource: User not authenticated, using mock user ID');
        return _addToCartWithMockUser(product, quantity);
      }

      // Check if product already exists in cart
      final existingItem = await _supabaseClient
          .from('cart_items')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', product.id)
          .maybeSingle();

      if (existingItem != null) {
        // Update quantity if already in cart
        final newQuantity = existingItem['quantity'] + quantity;

        final response = await _supabaseClient
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'added_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingItem['id'])
            .select('''
              id,
              product_id,
              quantity,
              added_at,
              products (
                id,
                name,
                description,
                price,
                sale_price,
                image_url,
                stock,
                brand,
                category_id,
                is_featured,
                is_active,
                created_at,
                updated_at,
                in_stock,
                average_rating,
                review_count
              )
            ''')
            .single();

        final productModel = ProductModel.fromJson(Map<String, dynamic>.from(response['products']));

        return CartItemModel(
          id: response['id'],
          product: productModel,
          quantity: response['quantity'],
          addedAt: DateTime.parse(response['added_at']),
        );
      } else {
        // Add new item to cart
        final response = await _supabaseClient
            .from('cart_items')
            .insert({
              'user_id': user.id,
              'product_id': product.id,
              'quantity': quantity,
              'added_at': DateTime.now().toIso8601String(),
              'selected': true,
              'saved_for_later': false,
            })
            .select('''
              id,
              product_id,
              quantity,
              added_at,
              products (
                id,
                name,
                description,
                price,
                sale_price,
                image_url,
                stock,
                brand,
                category_id,
                is_featured,
                is_active,
                created_at,
                updated_at,
                in_stock,
                average_rating,
                review_count
              )
            ''')
            .single();

        final productModel = ProductModel.fromJson(Map<String, dynamic>.from(response['products']));

        return CartItemModel(
          id: response['id'],
          product: productModel,
          quantity: response['quantity'],
          addedAt: DateTime.parse(response['added_at']),
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Failed to add item to cart: ${e.toString()}');
    }
  }

  @override
  Future<bool> removeFromCart({
    required String cartItemId,
  }) async {
    try {
      // Check authentication
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        // For testing purposes, use a mock user ID
        debugPrint('CartSupabaseDataSource: User not authenticated, using mock user ID for removeFromCart');
        return _removeFromCartWithMockUser(cartItemId);
      }

      // Delete the cart item, RLS policy will ensure user can only delete their own items
      await _supabaseClient
          .from('cart_items')
          .delete()
          .eq('id', cartItemId)
          .eq('user_id', user.id);

      return true;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Failed to remove item from cart: ${e.toString()}');
    }
  }

  @override
  Future<CartItemModel> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      // Check authentication
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        // For testing purposes, use a mock user ID
        debugPrint('CartSupabaseDataSource: User not authenticated, using mock user ID for updateQuantity');
        return _updateQuantityWithMockUser(cartItemId, quantity);
      }

      // Update cart item quantity
      final response = await _supabaseClient
          .from('cart_items')
          .update({
            'quantity': quantity,
          })
          .eq('id', cartItemId)
          .eq('user_id', user.id)
          .select('''
            id,
            product_id,
            quantity,
            added_at,
            products (
              id,
              name,
              description,
              price,
              sale_price,
              image_url,
              stock,
              brand,
              category_id,
              is_featured,
              is_active,
              created_at,
              updated_at,
              in_stock,
              average_rating,
              review_count
            )
          ''')
          .single();

      final productModel = ProductModel.fromJson(Map<String, dynamic>.from(response['products']));

      return CartItemModel(
        id: response['id'],
        product: productModel,
        quantity: response['quantity'],
        addedAt: DateTime.parse(response['added_at']),
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Failed to update cart item quantity: ${e.toString()}');
    }
  }

  @override
  Future<bool> clearCart() async {
    try {
      // Check authentication
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw ServerException(message: 'User is not authenticated');
      }

      // Delete all cart items for the user
      await _supabaseClient
          .from('cart_items')
          .delete()
          .eq('user_id', user.id);

      return true;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Failed to clear cart: ${e.toString()}');
    }
  }

  @override
  Future<double> getTotalPrice() async {
    try {
      // Check authentication
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw ServerException(message: 'User is not authenticated');
      }

      // Get cart items with product details to calculate total
      final items = await getCartItems();

      // Calculate total price
      double total = 0;
      for (var item in items) {
        total += item.totalPrice;
      }

      return total;
    } catch (e) {
      throw ServerException(message: 'Failed to get cart total price: ${e.toString()}');
    }
  }

  @override
  Future<int> getItemCount() async {
    try {
      // Check authentication
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw ServerException(message: 'User is not authenticated');
      }

      // Get count of cart items for user
      final response = await _supabaseClient
          .from('cart_items')
          .select('id')
          .eq('user_id', user.id);

      return (response as List).length;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Failed to get cart item count: ${e.toString()}');
    }
  }

  @override
  Future<bool> isInCart({
    required String productId,
  }) async {
    try {
      // Check authentication
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        // For testing purposes, use a mock user ID
        debugPrint('CartSupabaseDataSource: User not authenticated, using mock user ID for isInCart');
        return _isInCartWithMockUser(productId);
      }

      // Check if product exists in cart
      final response = await _supabaseClient
          .from('cart_items')
          .select('id')
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Failed to check if product is in cart: ${e.toString()}');
    }
  }

  /// Helper method to add to cart with a mock user ID for testing
  Future<CartItemModel> _addToCartWithMockUser(Product product, int quantity) async {
    // Create a mock cart item
    final mockCartItem = CartItemModel(
      id: uuid.v4(),
      product: product is ProductModel ? product : _convertToProductModel(product),
      quantity: quantity,
      addedAt: DateTime.now(),
    );

    // Store in local storage for persistence
    final prefs = await SharedPreferences.getInstance();

    // Get existing cart items
    final cartItemsJson = prefs.getStringList('mock_cart_items') ?? [];
    final cartItems = cartItemsJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();

    // Check if product already exists
    bool productExists = false;
    for (var i = 0; i < cartItems.length; i++) {
      if (cartItems[i]['product']['id'] == product.id) {
        // Update quantity
        cartItems[i]['quantity'] = (cartItems[i]['quantity'] as int) + quantity;
        productExists = true;
        break;
      }
    }

    // Add new item if product doesn't exist
    if (!productExists) {
      cartItems.add({
        'id': mockCartItem.id,
        'product': (mockCartItem.product as ProductModel).toJson(),
        'quantity': mockCartItem.quantity,
        'added_at': mockCartItem.addedAt.toIso8601String(),
      });
    }

    // Save updated cart items
    await prefs.setStringList(
      'mock_cart_items',
      cartItems.map((item) => jsonEncode(item)).toList(),
    );

    return mockCartItem;
  }

  /// Helper method to check if a product is in cart with a mock user ID for testing
  Future<bool> _isInCartWithMockUser(String productId) async {
    // Get cart items from local storage
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList('mock_cart_items') ?? [];

    // Check if product exists in cart
    for (final itemJson in cartItemsJson) {
      final item = jsonDecode(itemJson) as Map<String, dynamic>;
      final product = item['product'] as Map<String, dynamic>;

      if (product['id'] == productId) {
        return true;
      }
    }

    return false;
  }

  /// Helper method to remove from cart with a mock user ID for testing
  Future<bool> _removeFromCartWithMockUser(String cartItemId) async {
    // Get cart items from local storage
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList('mock_cart_items') ?? [];

    // Find and remove the cart item
    final updatedCartItems = <String>[];
    bool found = false;

    for (final itemJson in cartItemsJson) {
      final item = jsonDecode(itemJson) as Map<String, dynamic>;

      if (item['id'] != cartItemId) {
        // Keep all items except the one to remove
        updatedCartItems.add(itemJson);
      } else {
        found = true;
      }
    }

    if (found) {
      // Save updated cart items
      await prefs.setStringList('mock_cart_items', updatedCartItems);
      return true;
    }

    return false;
  }

  /// Helper method to update quantity with a mock user ID for testing
  Future<CartItemModel> _updateQuantityWithMockUser(String cartItemId, int quantity) async {
    // Get cart items from local storage
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList('mock_cart_items') ?? [];

    // Find and update the cart item
    CartItemModel? updatedItem;
    final updatedCartItems = <String>[];

    for (final itemJson in cartItemsJson) {
      final item = jsonDecode(itemJson) as Map<String, dynamic>;

      if (item['id'] == cartItemId) {
        // Update quantity
        item['quantity'] = quantity;

        // Create updated cart item model
        final productJson = item['product'] as Map<String, dynamic>;
        final productModel = ProductModel.fromJson(productJson);

        updatedItem = CartItemModel(
          id: item['id'],
          product: productModel,
          quantity: quantity,
          addedAt: DateTime.parse(item['added_at']),
        );
      }

      // Add all items to updated list
      updatedCartItems.add(jsonEncode(item));
    }

    if (updatedItem != null) {
      // Save updated cart items
      await prefs.setStringList('mock_cart_items', updatedCartItems);
      return updatedItem;
    }

    throw ServerException(message: 'Cart item not found');
  }

  /// Helper method to convert a Product entity to a ProductModel
  ProductModel _convertToProductModel(Product product) {
    try {
      return ProductModel.fromProduct(product);
    } catch (e) {
      debugPrint('Error using ProductModel.fromProduct: $e');

      // Fallback to manual conversion
      return ProductModel(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        discountPercentage: product.discountPercentage,
        rating: product.rating,
        reviewCount: product.reviewCount,
        mainImageUrl: product.mainImageUrl,
        additionalImages: product.additionalImages,
        inStock: product.inStock,
        stockQuantity: product.stockQuantity,
        categoryId: product.categoryId,
        subcategoryId: product.subcategoryId,
        brand: product.brand,
        attributes: product.attributes,
        tags: product.tags,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
    }
  }
}