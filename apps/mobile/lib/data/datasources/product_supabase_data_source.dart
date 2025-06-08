import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';
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
      debugPrint('ProductSupabaseDataSource: Fetching products from Supabase');

      // Start building the query
      var query = supabaseClient
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)');

      // Apply filters
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (subcategoryId != null) {
        query = query.eq('subcategory_id', subcategoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      // Apply sorting
      String orderBy = sortBy ?? 'created_at';
      bool orderAscending = ascending ?? false;

      // Apply pagination
      int? offset;
      if (page != null && limit != null) {
        offset = (page - 1) * limit;
      }

      // Execute the query with all parameters
      final response = await query
          .order(orderBy, ascending: orderAscending)
          .range(offset ?? 0, offset != null && limit != null ? offset + limit - 1 : 999)
          .limit(limit ?? 100);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} products');

      return _parseProductsResponse(response);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching products: $e');
      throw ServerException(
        message: 'Failed to fetch products from Supabase: ${e.toString()}',
      );
    }
  }

  /// Parse the response from Supabase into a list of ProductModel objects
  List<ProductModel> _parseProductsResponse(List<dynamic> response) {
    return response.map((json) {
      // Extract the main image URL from product_images
      String? imageUrl;
      if (json['product_images'] != null && json['product_images'].isNotEmpty) {
        // Find the primary image first
        var primaryImage = json['product_images'].firstWhere(
          (img) => img['is_primary'] == true,
          orElse: () => json['product_images'].isNotEmpty ? json['product_images'][0] : null,
        );

        if (primaryImage != null) {
          imageUrl = primaryImage['image_url'];
        }
      }

      // Extract category and subcategory names
      String? categoryName;
      if (json['categories'] != null) {
        categoryName = json['categories']['name'];
      }

      String? subcategoryName;
      if (json['subcategories'] != null) {
        subcategoryName = json['subcategories']['name'];
      }

      // Create a ProductModel from the JSON data
      final isOnSale = json['discount_percentage'] != null && (json['discount_percentage'] as num) > 0;

      // Create a Product entity first
      final product = Product(
        id: json['id'].toString(),
        name: json['name'] as String,
        description: json['description'] ?? '',
        price: (json['price'] as num).toDouble(),
        discountPercentage: json['discount_percentage'] != null
            ? (json['discount_percentage'] as num).toDouble()
            : null,
        rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
        reviewCount: json['review_count'] != null ? (json['review_count'] as num).toInt() : null,
        mainImageUrl: imageUrl ?? 'https://via.placeholder.com/150',
        additionalImages: _extractAdditionalImages(json['product_images']),
        inStock: json['stock_quantity'] != null ? (json['stock_quantity'] as num) > 0 : false,
        stockQuantity: json['stock_quantity'] != null ? (json['stock_quantity'] as num).toInt() : null,
        categoryId: json['category_id']?.toString() ?? '',
        subcategoryId: json['subcategory_id']?.toString(),
        brand: json['brand'],
        attributes: json['attributes'],
        tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        onSale: isOnSale,
        categoryName: categoryName,
        subcategoryName: subcategoryName,
      );

      // Convert to ProductModel
      return ProductModel.fromProduct(product);
    }).toList();
  }

  /// Extract additional images from the product_images array
  List<String>? _extractAdditionalImages(List<dynamic>? productImages) {
    if (productImages == null || productImages.isEmpty) {
      return null;
    }

    return productImages
        .map((img) => img['image_url'] as String)
        .toList();
  }

  /// Parse a single product response without images to avoid relationship errors
  ProductModel _parseProductResponseWithoutImages(Map<String, dynamic> json) {
    // Create a Product entity without images
    final product = Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      discountPercentage: json['discount_percentage'] != null
          ? (json['discount_percentage'] as num).toDouble()
          : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] != null ? (json['review_count'] as num).toInt() : null,
      mainImageUrl: 'https://via.placeholder.com/150', // Default placeholder
      additionalImages: null, // No additional images for now
      inStock: json['stock_quantity'] != null ? (json['stock_quantity'] as num) > 0 : false,
      stockQuantity: json['stock_quantity'] != null ? (json['stock_quantity'] as num).toInt() : null,
      categoryId: json['category_id']?.toString() ?? '',
      subcategoryId: json['subcategory_id']?.toString(),
      brand: json['brand'],
      onSale: json['discount_percentage'] != null && (json['discount_percentage'] as num) > 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );

    // Convert to ProductModel
    return ProductModel.fromProduct(product);
  }

  /// Get a single product by ID
  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      debugPrint('ProductSupabaseDataSource: Fetching product with ID: $id from Supabase');

      final response = await supabaseClient
          .from('products')
          .select('*')
          .eq('id', id)
          .single();

      debugPrint('ProductSupabaseDataSource: Retrieved product with ID: $id');

      // Parse the response without images to avoid relationship errors
      return _parseProductResponseWithoutImages(response);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching product: $e');
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
      debugPrint('ProductSupabaseDataSource: Fetching featured products from Supabase');

      final response = await supabaseClient
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(limit ?? 10);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} featured products');

      return _parseProductsResponse(response);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching featured products: $e');
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
      debugPrint('ProductSupabaseDataSource: Fetching sale products from Supabase');

      // Apply pagination
      int? offset;
      if (page != null && limit != null) {
        offset = (page - 1) * limit;
      }

      final response = await supabaseClient
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
          .not('discount_percentage', 'is', null)
          .gt('discount_percentage', 0)
          .order('discount_percentage', ascending: false)
          .range(offset ?? 0, offset != null && limit != null ? offset + limit - 1 : 999)
          .limit(limit ?? 20);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} sale products');

      return _parseProductsResponse(response);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching sale products: $e');
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
      debugPrint('ProductSupabaseDataSource: Fetching related products for product ID: $productId');

      // First, get the product to find its category
      final product = await getProductById(productId);
      final categoryId = product.categoryId;

      // Get products from the same category, excluding the current product
      final response = await supabaseClient
          .from('products')
          .select('*')
          .eq('category_id', categoryId)
          .neq('id', productId)
          .order('created_at', ascending: false)
          .limit(limit ?? 4);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} related products');

      // Parse the response without images to avoid relationship errors
      return response.map((json) => _parseProductResponseWithoutImages(json)).toList();
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching related products: $e');
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
      debugPrint('ProductSupabaseDataSource: Searching products with query: $query');

      // Apply pagination
      int? offset;
      if (page != null && limit != null) {
        offset = (page - 1) * limit;
      }

      // Use Supabase's full-text search capabilities
      final response = await supabaseClient
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
          .textSearch('name', query, config: 'english')
          .order('created_at', ascending: false)
          .range(offset ?? 0, offset != null && limit != null ? offset + limit - 1 : 999)
          .limit(limit ?? 20);

      // If no results with name search, try description search
      if (response.isEmpty) {
        final descriptionResponse = await supabaseClient
            .from('products')
            .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
            .textSearch('description', query, config: 'english')
            .order('created_at', ascending: false)
            .range(offset ?? 0, offset != null && limit != null ? offset + limit - 1 : 999)
            .limit(limit ?? 20);

        return _parseProductsResponse(descriptionResponse);
      }

      debugPrint('ProductSupabaseDataSource: Found ${response.length} products matching query: $query');

      return _parseProductsResponse(response);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error searching products: $e');
      throw ServerException(
        message: 'Failed to search products from Supabase: ${e.toString()}',
      );
    }
  }

  /// Get products by category ID
  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      debugPrint('ProductSupabaseDataSource: Fetching products for category ID: $categoryId');

      final response = await supabaseClient
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} products for category ID: $categoryId');

      return _parseProductsResponse(response);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching products by category: $e');
      throw ServerException(
        message: 'Failed to fetch products by category from Supabase: ${e.toString()}',
      );
    }
  }

  /// Get products by a list of IDs
  @override
  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) {
        return [];
      }

      debugPrint('ProductSupabaseDataSource: Fetching products for IDs: $ids');

      // Supabase doesn't have a direct 'in' operator, so we'll use a workaround
      // We'll fetch products one by one and combine the results
      List<dynamic> allResults = [];

      for (final id in ids) {
        final response = await supabaseClient
            .from('products')
            .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
            .eq('id', id);

        if (response.isNotEmpty) {
          allResults.addAll(response);
        }
      }

      debugPrint('ProductSupabaseDataSource: Retrieved ${allResults.length} products for IDs: $ids');

      return _parseProductsResponse(allResults);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching products by IDs: $e');
      throw ServerException(
        message: 'Failed to fetch products by IDs from Supabase: ${e.toString()}',
      );
    }
  }
}
