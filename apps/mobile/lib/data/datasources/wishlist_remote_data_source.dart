import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/errors/exceptions.dart';
import '../models/wishlist_item_model.dart';
import '../models/product_model.dart';
import '../../core/constants/api_constants.dart';

/// Interface for wishlist remote data source
abstract class WishlistRemoteDataSource {
  /// Get all wishlist items for the current user
  Future<List<WishlistItemModel>> getWishlistItems();

  /// Add a product to the wishlist
  Future<WishlistItemModel> addToWishlist(String productId);

  /// Remove a product from the wishlist
  Future<bool> removeFromWishlist(String productId);

  /// Check if a product is in the wishlist
  Future<bool> isInWishlist(String productId);

  /// Clear the wishlist
  Future<bool> clearWishlist();

  /// Get product details for all wishlist items
  Future<List<ProductModel>> getWishlistProducts();
}

/// Implementation of [WishlistRemoteDataSource] for Supabase backend
class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final http.Client client;
  final String baseUrl;
  final String authToken;
  final uuid = const Uuid();

  WishlistRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
    required this.authToken,
  });

  @override
  Future<List<WishlistItemModel>> getWishlistItems() async {
    final url = Uri.parse('$baseUrl${ApiConstants.wishlistEndpoint}');
    
    try {
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => WishlistItemModel.fromJson(item))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch wishlist items: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Error fetching wishlist items: ${e.toString()}',
      );
    }
  }

  @override
  Future<WishlistItemModel> addToWishlist(String productId) async {
    final url = Uri.parse('$baseUrl${ApiConstants.addToWishlistEndpoint}');
    
    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'product_id': productId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return WishlistItemModel.fromJson(jsonData);
      } else {
        throw ServerException(
          message: 'Failed to add item to wishlist: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Error adding item to wishlist: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> removeFromWishlist(String productId) async {
    final url = Uri.parse('$baseUrl${ApiConstants.removeFromWishlistEndpoint}');
    
    try {
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'product_id': productId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          message: 'Failed to remove item from wishlist: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Error removing item from wishlist: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> isInWishlist(String productId) async {
    try {
      final items = await getWishlistItems();
      return items.any((item) => item.productId == productId);
    } catch (e) {
      throw ServerException(
        message: 'Error checking if item is in wishlist: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> clearWishlist() async {
    final url = Uri.parse('$baseUrl${ApiConstants.wishlistEndpoint}');
    
    try {
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          message: 'Failed to clear wishlist: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Error clearing wishlist: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ProductModel>> getWishlistProducts() async {
    try {
      final wishlistItems = await getWishlistItems();
      
      if (wishlistItems.isEmpty) {
        return [];
      }
      
      final productIds = wishlistItems.map((item) => item.productId).join(',');
      final url = Uri.parse('$baseUrl${ApiConstants.productsEndpoint}?ids=$productIds');
      
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => ProductModel.fromJson(item))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch wishlist products: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Error fetching wishlist products: ${e.toString()}',
      );
    }
  }
} 