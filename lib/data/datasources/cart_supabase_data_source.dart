import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/product.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'cart_remote_data_source.dart';

/// Implementation of [CartRemoteDataSource] for Supabase backend
class CartSupabaseDataSource implements CartRemoteDataSource {
  final SupabaseClient _supabaseClient;
  final uuid = const Uuid();

  CartSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

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
        throw ServerException(message: 'User is not authenticated');
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
        throw ServerException(message: 'User is not authenticated');
      }

      // Delete the cart item, RLS policy will ensure user can only delete their own items
      final response = await _supabaseClient
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
        throw ServerException(message: 'User is not authenticated');
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
        throw ServerException(message: 'User is not authenticated');
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
} 