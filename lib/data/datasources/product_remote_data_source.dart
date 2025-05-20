import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/api_constants.dart';
import '../mock/mock_products.dart';

/// Interface for the remote data source for product data
abstract class ProductRemoteDataSource {
  /// Get a list of products with optional filters
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
  });

  /// Get a single product by ID
  Future<ProductModel> getProductById(String id);

  /// Get featured products
  Future<List<ProductModel>> getFeaturedProducts({
    int? limit,
  });

  /// Get products on sale (with discount)
  Future<List<ProductModel>> getProductsOnSale({
    int? page,
    int? limit,
  });

  /// Get related products for a specific product
  Future<List<ProductModel>> getRelatedProducts({
    required String productId,
    int? limit,
  });

  /// Search products by query
  Future<List<ProductModel>> searchProducts({
    required String query,
    int? page,
    int? limit,
  });

  /// Get products by category ID
  Future<List<ProductModel>> getProductsByCategory(String categoryId);

  /// Get products by a list of IDs
  Future<List<ProductModel>> getProductsByIds(List<String> ids);
}

/// Implementation of the ProductRemoteDataSource interface
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final http.Client client;

  ProductRemoteDataSourceImpl({required this.client});

  /// Helper method to build query parameters
  Map<String, String> _buildQueryParams({
    int? page,
    int? limit,
    String? categoryId,
    String? subcategoryId,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
    double? minPrice,
    double? maxPrice,
  }) {
    final Map<String, String> params = {};

    if (page != null) params['page'] = page.toString();
    if (limit != null) params['limit'] = limit.toString();
    if (categoryId != null) params['category_id'] = categoryId;
    if (subcategoryId != null) params['subcategory_id'] = subcategoryId;
    if (searchQuery != null) params['search'] = searchQuery;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (ascending != null) params['ascending'] = ascending.toString();
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();

    return params;
  }

  /// Helper method to handle responses
  List<ProductModel> _handleProductListResponse(http.Response response) {
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['data'] != null) {
        return (jsonData['data'] as List)
            .map((productJson) => ProductModel.fromJson(productJson))
            .toList();
      } else {
        return [];
      }
    } else {
      throw ServerException(
        message: 'Failed to load products',
        statusCode: response.statusCode,
        data: response.body,
      );
    }
  }

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
    final params = _buildQueryParams(
      page: page,
      limit: limit,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      searchQuery: searchQuery,
      sortBy: sortBy,
      ascending: ascending,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    final uri = Uri.parse(ApiConstants.baseApiUrl + ApiConstants.productsEndpoint)
        .replace(queryParameters: params);

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return _handleProductListResponse(response);
    } on Exception {
      throw ServerException(
        message: 'Failed to connect to the server',
      );
    }
  }

  /// Get a single product by ID
  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      // For now, return a mock product
      debugPrint('ProductRemoteDataSourceImpl: Returning mock product for ID: $id');
      final mockProducts = MockProducts.getMockProducts();
      final product = mockProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => mockProducts.first, // Fallback to first product if ID not found
      );

      return ProductModel.fromProduct(product);
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch product details: ${e.toString()}',
      );
    }
  }

  /// Get featured products
  @override
  Future<List<ProductModel>> getFeaturedProducts({int? limit}) async {
    final params = limit != null ? {'limit': limit.toString()} : null;

    final uri = Uri.parse(ApiConstants.baseApiUrl + ApiConstants.featuredProductsEndpoint)
        .replace(queryParameters: params);

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return _handleProductListResponse(response);
    } on Exception {
      throw ServerException(
        message: 'Failed to connect to the server',
      );
    }
  }

  /// Get products on sale (with discount)
  @override
  Future<List<ProductModel>> getProductsOnSale({
    int? page,
    int? limit,
  }) async {
    final params = _buildQueryParams(
      page: page,
      limit: limit,
    );

    // Assuming we have a specific endpoint for sale products, otherwise we'd need to modify this
    final uri = Uri.parse(ApiConstants.baseApiUrl + '/products/on-sale')
        .replace(queryParameters: params);

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return _handleProductListResponse(response);
    } on Exception {
      throw ServerException(
        message: 'Failed to connect to the server',
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
      debugPrint('ProductRemoteDataSourceImpl: Returning mock related products for ID: $productId');
      return MockProducts.getMockProducts()
        .where((p) => p.id != productId) // Exclude the current product
        .take(limit ?? 4)
        .map((product) => ProductModel.fromProduct(product))
        .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch related products: ${e.toString()}',
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
    final params = _buildQueryParams(
      page: page,
      limit: limit,
      searchQuery: query,
    );

    final uri = Uri.parse(ApiConstants.baseApiUrl + ApiConstants.searchProductsEndpoint)
        .replace(queryParameters: params);

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return _handleProductListResponse(response);
    } on Exception {
      throw ServerException(
        message: 'Failed to connect to the server',
      );
    }
  }

  /// Get products by category ID
  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final params = {'category_id': categoryId};

    final uri = Uri.parse(ApiConstants.baseApiUrl + ApiConstants.productsEndpoint)
        .replace(queryParameters: params);

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return _handleProductListResponse(response);
    } on Exception {
      throw ServerException(
        message: 'Failed to connect to the server',
      );
    }
  }

  /// Get products by a list of IDs
  @override
  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    final params = {'ids': ids.join(',')};

    final uri = Uri.parse(ApiConstants.baseApiUrl + '/products/by-ids')
        .replace(queryParameters: params);

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return _handleProductListResponse(response);
    } on Exception {
      throw ServerException(
        message: 'Failed to connect to the server',
      );
    }
  }
}