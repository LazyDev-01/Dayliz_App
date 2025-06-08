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
      // Check authentication with detailed logging
      final user = _supabaseClient.auth.currentUser;
      final session = _supabaseClient.auth.currentSession;

      debugPrint('🔐 CART SUPABASE: Getting cart items...');
      debugPrint('🔐 CART SUPABASE: User: ${user?.id ?? 'null'}');
      debugPrint('🔐 CART SUPABASE: Session: ${session != null ? 'exists' : 'null'}');

      if (user == null) {
        debugPrint('🔐 CART SUPABASE: ❌ User not authenticated, returning empty cart');
        return [];
      }

      debugPrint('🔐 CART SUPABASE: ✅ User authenticated, fetching cart items...');

      // Get cart items for the current user (simplified without join)
      final response = await _supabaseClient
          .from('cart_items')
          .select('id, product_id, quantity, added_at')
          .eq('user_id', user.id)
          .order('added_at', ascending: false);

      debugPrint('🔐 CART SUPABASE: ✅ Found ${response.length} cart items in database');

      // Fetch real product details for each cart item
      final cartItems = <CartItemModel>[];

      for (final item in response) {
        try {
          debugPrint('🔐 CART SUPABASE: Fetching product details for: ${item['product_id']}');

          // Fetch product details separately
          final productResponse = await _supabaseClient
              .from('products')
              .select('*')
              .eq('id', item['product_id'])
              .single();

          debugPrint('🔐 CART SUPABASE: ✅ Product details fetched: ${productResponse['name']}');

          // Create ProductModel from fetched data with robust mapping
          final productModel = _createProductModelFromSupabaseData(productResponse);

          // Create CartItemModel with real product data
          final cartItem = CartItemModel(
            id: item['id'],
            product: productModel,
            quantity: item['quantity'],
            addedAt: DateTime.parse(item['added_at']),
          );

          cartItems.add(cartItem);
        } catch (e) {
          debugPrint('🔐 CART SUPABASE: ❌ Failed to fetch product ${item['product_id']}: $e');

          // Fallback to placeholder if product fetch fails
          final placeholderProduct = ProductModel(
            id: item['product_id'],
            name: 'Product (ID: ${item['product_id']})',
            description: 'Product details unavailable',
            price: 0.0,
            discountPercentage: 0.0,
            rating: 0.0,
            reviewCount: 0,
            mainImageUrl: '',
            additionalImages: const [],
            inStock: true,
            stockQuantity: 100,
            categoryId: '',
            subcategoryId: '',
            brand: '',
            attributes: const {},
            tags: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final cartItem = CartItemModel(
            id: item['id'],
            product: placeholderProduct,
            quantity: item['quantity'],
            addedAt: DateTime.parse(item['added_at']),
          );

          cartItems.add(cartItem);
        }
      }

      debugPrint('🔐 CART SUPABASE: ✅ Successfully processed ${cartItems.length} cart items with product details');
      return cartItems;
    } on PostgrestException catch (e) {
      debugPrint('🔐 CART SUPABASE: ❌ Database error: ${e.message}');
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      debugPrint('🔐 CART SUPABASE: ❌ Get cart items failed: $e');
      throw ServerException(message: 'Failed to get cart items: ${e.toString()}');
    }
  }

  @override
  Future<CartItemModel> addToCart({
    required Product product,
    required int quantity,
  }) async {
    try {
      // Check authentication with detailed logging
      final user = _supabaseClient.auth.currentUser;
      final session = _supabaseClient.auth.currentSession;

      debugPrint('🔐 CART SUPABASE: Checking authentication...');
      debugPrint('🔐 CART SUPABASE: User: ${user?.id ?? 'null'}');
      debugPrint('🔐 CART SUPABASE: Session: ${session != null ? 'exists' : 'null'}');

      if (user == null) {
        debugPrint('🔐 CART SUPABASE: ❌ User not authenticated');
        throw ServerException(message: 'User is not authenticated. Please login to sync cart with database.');
      }

      debugPrint('🔐 CART SUPABASE: ✅ User authenticated, proceeding with database operation...');

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
            .select('id, product_id, quantity, added_at')
            .single();

        debugPrint('🔐 CART SUPABASE: ✅ Cart item updated successfully: ${response['id']}');

        // Convert Product entity to ProductModel
        final productModel = product is ProductModel
            ? product
            : _convertToProductModel(product);

        return CartItemModel(
          id: response['id'],
          product: productModel,
          quantity: response['quantity'],
          addedAt: DateTime.parse(response['added_at']),
        );
      } else {
        // Add new item to cart (simplified without join)
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
            .select('id, product_id, quantity, added_at')
            .single();

        debugPrint('🔐 CART SUPABASE: ✅ Cart item inserted successfully: ${response['id']}');

        // Convert Product entity to ProductModel
        final productModel = product is ProductModel
            ? product
            : _convertToProductModel(product);

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
      // Check authentication with detailed logging
      final user = _supabaseClient.auth.currentUser;
      final session = _supabaseClient.auth.currentSession;

      debugPrint('🔐 CART SUPABASE: Checking authentication for update quantity...');
      debugPrint('🔐 CART SUPABASE: User: ${user?.id ?? 'null'}');
      debugPrint('🔐 CART SUPABASE: Session: ${session != null ? 'exists' : 'null'}');

      if (user == null) {
        debugPrint('🔐 CART SUPABASE: ❌ User not authenticated');
        throw ServerException(message: 'User is not authenticated. Please login to sync cart with database.');
      }

      debugPrint('🔐 CART SUPABASE: ✅ User authenticated, proceeding with quantity update...');

      // Update cart item quantity (simplified without join)
      final response = await _supabaseClient
          .from('cart_items')
          .update({
            'quantity': quantity,
          })
          .eq('id', cartItemId)
          .eq('user_id', user.id)
          .select('id, product_id, quantity, added_at')
          .single();

      debugPrint('🔐 CART SUPABASE: ✅ Cart item quantity updated successfully: ${response['id']}');

      // Fetch real product details
      try {
        debugPrint('🔐 CART SUPABASE: Fetching product details for: ${response['product_id']}');

        final productResponse = await _supabaseClient
            .from('products')
            .select('*')
            .eq('id', response['product_id'])
            .single();

        debugPrint('🔐 CART SUPABASE: ✅ Product details fetched: ${productResponse['name']}');

        final productModel = _createProductModelFromSupabaseData(productResponse);

        return CartItemModel(
          id: response['id'],
          product: productModel,
          quantity: response['quantity'],
          addedAt: DateTime.parse(response['added_at']),
        );
      } catch (e) {
        debugPrint('🔐 CART SUPABASE: ❌ Failed to fetch product details: $e');

        // Fallback to placeholder
        final placeholderProduct = ProductModel(
          id: response['product_id'],
          name: 'Product (ID: ${response['product_id']})',
          description: 'Product details unavailable',
          price: 0.0,
          discountPercentage: 0.0,
          rating: 0.0,
          reviewCount: 0,
          mainImageUrl: '',
          additionalImages: const [],
          inStock: true,
          stockQuantity: 100,
          categoryId: '',
          subcategoryId: '',
          brand: '',
          attributes: const {},
          tags: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return CartItemModel(
          id: response['id'],
          product: placeholderProduct,
          quantity: response['quantity'],
          addedAt: DateTime.parse(response['added_at']),
        );
      }
    } on PostgrestException catch (e) {
      debugPrint('🔐 CART SUPABASE: ❌ Database error: ${e.message}');
      throw ServerException(message: 'Database error: ${e.message}');
    } catch (e) {
      debugPrint('🔐 CART SUPABASE: ❌ Update quantity failed: $e');
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

  /// Robust method to create ProductModel from Supabase data with proper field mapping
  ProductModel _createProductModelFromSupabaseData(Map<String, dynamic> data) {
    try {
      debugPrint('🔐 CART SUPABASE: Mapping product data: ${data.keys.toList()}');

      // Handle different possible field names and null values
      final id = data['id']?.toString() ?? '';
      final name = data['name']?.toString() ?? 'Unknown Product';
      final description = data['description']?.toString() ?? '';

      // Handle price with multiple possible field names
      double price = 0.0;
      if (data['price'] != null) {
        price = (data['price'] as num).toDouble();
      } else if (data['retail_price'] != null) {
        price = (data['retail_price'] as num).toDouble();
      } else if (data['sale_price'] != null) {
        price = (data['sale_price'] as num).toDouble();
      }

      // Handle discount percentage
      double? discountPercentage;
      if (data['discount_percentage'] != null) {
        discountPercentage = (data['discount_percentage'] as num).toDouble();
      }

      // Handle rating
      double? rating;
      if (data['rating'] != null) {
        rating = (data['rating'] as num).toDouble();
      } else if (data['average_rating'] != null) {
        rating = (data['average_rating'] as num).toDouble();
      }

      // Handle review count
      int? reviewCount;
      if (data['review_count'] != null) {
        reviewCount = (data['review_count'] as num).toInt();
      }

      // Handle image URL with multiple possible field names
      String mainImageUrl = '';
      if (data['main_image_url'] != null && data['main_image_url'].toString().isNotEmpty) {
        mainImageUrl = data['main_image_url'].toString();
      } else if (data['image_url'] != null && data['image_url'].toString().isNotEmpty) {
        mainImageUrl = data['image_url'].toString();
      } else {
        mainImageUrl = 'https://via.placeholder.com/150';
      }

      // Handle additional images
      List<String>? additionalImages;
      if (data['additional_images'] != null) {
        if (data['additional_images'] is List) {
          additionalImages = List<String>.from(data['additional_images']);
        }
      }

      // Handle stock status
      bool inStock = true;
      int? stockQuantity;
      if (data['in_stock'] != null) {
        inStock = data['in_stock'] as bool;
      } else if (data['is_in_stock'] != null) {
        inStock = data['is_in_stock'] as bool;
      }

      if (data['stock_quantity'] != null) {
        stockQuantity = (data['stock_quantity'] as num).toInt();
        inStock = stockQuantity > 0;
      }

      // Handle category
      final categoryId = data['category_id']?.toString() ?? '';
      final subcategoryId = data['subcategory_id']?.toString();

      // Handle brand
      final brand = data['brand']?.toString();

      // Handle attributes with special focus on weight/unit extraction
      Map<String, dynamic>? attributes;
      if (data['attributes'] != null && data['attributes'] is Map) {
        attributes = Map<String, dynamic>.from(data['attributes']);
      } else {
        // Create attributes map if it doesn't exist
        attributes = <String, dynamic>{};
      }

      // Extract weight/unit information from various possible sources
      String? weightUnit;

      // Check if weight is in attributes
      if (attributes['weight'] != null) {
        weightUnit = attributes['weight'].toString();
      } else if (attributes['unit'] != null) {
        weightUnit = attributes['unit'].toString();
      } else if (attributes['quantity'] != null) {
        weightUnit = attributes['quantity'].toString();
      } else if (attributes['volume'] != null) {
        weightUnit = attributes['volume'].toString();
      }

      // Check if weight is in a separate database field
      if (weightUnit == null || weightUnit.isEmpty) {
        if (data['weight'] != null && data['weight'].toString().isNotEmpty) {
          weightUnit = data['weight'].toString();
          attributes['weight'] = weightUnit;
        } else if (data['unit'] != null && data['unit'].toString().isNotEmpty) {
          weightUnit = data['unit'].toString();
          attributes['weight'] = weightUnit;
        } else if (data['package_size'] != null && data['package_size'].toString().isNotEmpty) {
          weightUnit = data['package_size'].toString();
          attributes['weight'] = weightUnit;
        }
      }

      // If still no weight found, try to extract from product name
      if (weightUnit == null || weightUnit.isEmpty) {
        final nameMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(g|kg|ml|l|gm|gram|grams|liter|liters|piece|pieces|pc|pcs)',
                                 caseSensitive: false).firstMatch(name);
        if (nameMatch != null) {
          weightUnit = '${nameMatch.group(1)}${nameMatch.group(2)}';
          attributes['weight'] = weightUnit;
        }
      }

      // Ensure weight is properly stored in attributes
      if (weightUnit != null && weightUnit.isNotEmpty) {
        attributes['weight'] = weightUnit;
        debugPrint('🔐 CART SUPABASE: Weight extracted: $weightUnit');
      } else {
        debugPrint('🔐 CART SUPABASE: ⚠️ No weight found for product: $name');
      }

      // Handle tags
      List<String>? tags;
      if (data['tags'] != null && data['tags'] is List) {
        tags = List<String>.from(data['tags']);
      }

      // Handle timestamps
      DateTime? createdAt;
      DateTime? updatedAt;

      if (data['created_at'] != null) {
        try {
          createdAt = DateTime.parse(data['created_at'].toString());
        } catch (e) {
          debugPrint('🔐 CART SUPABASE: Failed to parse created_at: $e');
        }
      }

      if (data['updated_at'] != null) {
        try {
          updatedAt = DateTime.parse(data['updated_at'].toString());
        } catch (e) {
          debugPrint('🔐 CART SUPABASE: Failed to parse updated_at: $e');
        }
      }

      final productModel = ProductModel(
        id: id,
        name: name,
        description: description,
        price: price,
        discountPercentage: discountPercentage,
        rating: rating,
        reviewCount: reviewCount,
        mainImageUrl: mainImageUrl,
        additionalImages: additionalImages,
        inStock: inStock,
        stockQuantity: stockQuantity,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        brand: brand,
        attributes: attributes,
        tags: tags,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      debugPrint('🔐 CART SUPABASE: ✅ Product mapped successfully: $name (₹$price) - ${weightUnit ?? 'No weight'}');
      return productModel;

    } catch (e) {
      debugPrint('🔐 CART SUPABASE: ❌ Error mapping product data: $e');

      // Return a safe fallback product
      return ProductModel(
        id: data['id']?.toString() ?? 'unknown',
        name: data['name']?.toString() ?? 'Product Error',
        description: 'Failed to load product details',
        price: 0.0,
        discountPercentage: null,
        rating: null,
        reviewCount: null,
        mainImageUrl: 'https://via.placeholder.com/150',
        additionalImages: const [],
        inStock: false,
        stockQuantity: 0,
        categoryId: '',
        subcategoryId: null,
        brand: null,
        attributes: const {},
        tags: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
}