import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/exceptions.dart';
import '../models/product_model.dart';
import '../mock/mock_products.dart';
import 'product_remote_data_source.dart';

/// Implementation of the ProductRemoteDataSource interface using Supabase
class ProductSupabaseDataSource implements ProductRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProductSupabaseDataSource({required this.supabaseClient});

  /// Get a list of products with optional filters
  @override
  Future<List<ProductModel>> getProducts({
    int? page,
    int? limit,
    String? categoryId,
    String? subcategoryId,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      // For now, return mock data
      // In the future, this will be replaced with actual Supabase queries
      debugPrint('ProductSupabaseDataSource: Returning mock products');
      return MockProducts.getMockProducts().map((product) => 
        ProductModel.fromProduct(product)).toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch products from Supabase: ${e.toString()}',
      );
    }
  }

  /// Get a single product by ID
  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      // For now, return a mock product
      // In the future, this will be replaced with actual Supabase queries
      debugPrint('ProductSupabaseDataSource: Returning mock product for ID: $id');
      final mockProducts = MockProducts.getMockProducts();
      final product = mockProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => mockProducts.first, // Fallback to first product if ID not found
      );
      
      return ProductModel.fromProduct(product);
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch product details from Supabase: ${e.toString()}',
      );
    }
  }

  /// Get featured products
  @override
  Future<List<ProductModel>> getFeaturedProducts({
    int? limit,
  }) async {
    try {
      // For now, return mock data
      debugPrint('ProductSupabaseDataSource: Returning mock featured products');
      return MockProducts.getMockProducts()
        .where((p) => p.id.contains('1') || p.id.contains('3')) // Just a simple filter for mocking
        .map((product) => ProductModel.fromProduct(product))
        .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch featured products from Supabase: ${e.toString()}',
      );
    }
  }

  /// Get products on sale (with discount)
  @override
  Future<List<ProductModel>> getProductsOnSale({
    int? page,
    int? limit,
  }) async {
    try {
      // For now, return mock data
      debugPrint('ProductSupabaseDataSource: Returning mock sale products');
      return MockProducts.getMockProducts()
        .where((p) => p.discountPercentage != null)
        .map((product) => ProductModel.fromProduct(product))
        .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch sale products from Supabase: ${e.toString()}',
      );
    }
  }

  /// Get related products for a specific product
  @override
  Future<List<ProductModel>> getRelatedProducts({
    required String productId,
    int? limit,
  }) async {
    try {
      // For now, return mock data
      debugPrint('ProductSupabaseDataSource: Returning mock related products for ID: $productId');
      return MockProducts.getMockProducts()
        .where((p) => p.id != productId) // Exclude the current product
        .take(limit ?? 4)
        .map((product) => ProductModel.fromProduct(product))
        .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch related products from Supabase: ${e.toString()}',
      );
    }
  }

  /// Search products by query
  @override
  Future<List<ProductModel>> searchProducts({
    required String query,
    int? page,
    int? limit,
  }) async {
    try {
      // For now, return mock data filtered by query
      debugPrint('ProductSupabaseDataSource: Searching mock products with query: $query');
      return MockProducts.getMockProducts()
        .where((p) => 
          p.name.toLowerCase().contains(query.toLowerCase()) || 
          p.description.toLowerCase().contains(query.toLowerCase()))
        .map((product) => ProductModel.fromProduct(product))
        .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to search products from Supabase: ${e.toString()}',
      );
    }
  }
  
  /// Get products by category ID
  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      // For now, return mock data filtered by category
      debugPrint('ProductSupabaseDataSource: Returning mock products for category: $categoryId');
      return MockProducts.getMockProducts()
        .where((p) => p.categoryId == categoryId)
        .map((product) => ProductModel.fromProduct(product))
        .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch products by category from Supabase: ${e.toString()}',
      );
    }
  }
  
  /// Get products by a list of IDs
  @override
  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    try {
      // For now, return mock data filtered by IDs
      debugPrint('ProductSupabaseDataSource: Returning mock products for IDs: $ids');
      return MockProducts.getMockProducts()
        .where((p) => ids.contains(p.id))
        .map((product) => ProductModel.fromProduct(product))
        .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch products by IDs from Supabase: ${e.toString()}',
      );
    }
  }
}
