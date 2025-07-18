import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/exceptions.dart';
import '../../core/models/pagination_models.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';
import 'product_remote_data_source.dart';

/// Implementation of the ProductRemoteDataSource interface using Supabase
class ProductSupabaseDataSource implements ProductRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProductSupabaseDataSource({required this.supabaseClient});

  /// Get products with pagination support
  Future<PaginatedResponse<ProductModel>> getProductsPaginated({
    PaginationParams? pagination,
    String? categoryId,
    String? subcategoryId,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final paginationParams = pagination ?? const PaginationParams.defaultProducts();
      debugPrint('ProductSupabaseDataSource: Fetching paginated products (page: ${paginationParams.page}, limit: ${paginationParams.limit})');

      // Build the base query using the view with images
      var query = supabaseClient
          .from('products_with_images')
          .select('*');

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

      // Get total count for pagination metadata
      // For now, we'll use a simplified approach to get total count
      // In production, you might want to implement a more efficient counting method
      var countQuery = supabaseClient.from('products_with_images').select('id');

      // Apply same filters to count query
      if (categoryId != null) {
        countQuery = countQuery.eq('category_id', categoryId);
      }
      if (subcategoryId != null) {
        countQuery = countQuery.eq('subcategory_id', subcategoryId);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        countQuery = countQuery.ilike('name', '%$searchQuery%');
      }
      if (minPrice != null) {
        countQuery = countQuery.gte('price', minPrice);
      }
      if (maxPrice != null) {
        countQuery = countQuery.lte('price', maxPrice);
      }

      final countResponse = await countQuery;
      final totalItems = countResponse.length;

      // Execute the main query with pagination
      final response = await query
          .order(orderBy, ascending: orderAscending)
          .range(paginationParams.offset, paginationParams.offset + paginationParams.limit - 1);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} products (total: $totalItems)');

      final products = _parseProductsResponseFromView(response);
      final meta = PaginationMeta.fromParams(
        params: paginationParams,
        totalItems: totalItems,
      );

      return PaginatedResponse(data: products, meta: meta);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching paginated products: $e');
      throw ServerException(
        message: 'Failed to fetch products from Supabase: ${e.toString()}',
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
    try {
      debugPrint('ProductSupabaseDataSource: Fetching products from Supabase');

      // Calculate pagination parameters
      int? offset;
      if (page != null && limit != null) {
        offset = (page - 1) * limit;
      }

      // Use the robust view with proper image handling
      var query = supabaseClient
          .from('products_with_images')
          .select('*');

      // Apply filters
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (subcategoryId != null) {
        query = query.eq('subcategory_id', subcategoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('product_name.ilike.%$searchQuery%,name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      // Apply sorting
      String orderBy = sortBy ?? 'created_at';
      bool orderAscending = ascending ?? false;

      final response = await query
          .order(orderBy, ascending: orderAscending)
          .range(offset ?? 0, offset != null && limit != null ? offset + limit - 1 : (limit ?? 100) - 1);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} products');

      // Apply additional filters that aren't handled by the database function
      List<dynamic> filteredResponse = response;

      if (minPrice != null || maxPrice != null) {
        filteredResponse = response.where((product) {
          final price = product['retail_sale_price'] ?? product['mrp'] ?? product['price'] ?? 0;
          final productPrice = (price as num).toDouble();

          if (minPrice != null && productPrice < minPrice) return false;
          if (maxPrice != null && productPrice > maxPrice) return false;

          return true;
        }).toList();
      }

      // Apply sorting if different from default
      if (sortBy != null && sortBy != 'created_at') {
        filteredResponse.sort((a, b) {
          dynamic aValue = a[sortBy];
          dynamic bValue = b[sortBy];

          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return ascending == true ? -1 : 1;
          if (bValue == null) return ascending == true ? 1 : -1;

          int comparison = aValue.toString().compareTo(bValue.toString());
          return ascending == true ? comparison : -comparison;
        });
      }

      return _parseProductsResponseFromView(filteredResponse);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching products: $e');
      throw ServerException(
        message: 'Failed to fetch products from Supabase: ${e.toString()}',
      );
    }
  }


  /// Parse the response from the view into a list of ProductModel objects
  List<ProductModel> _parseProductsResponseFromView(List<dynamic> response) {
    return response.map((json) {
      // The view provides main_image_url directly
      final imageUrl = json['main_image_url'] as String?;

      // Create a Product entity from the view response
      final isOnSale = json['discount_percentage'] != null && (json['discount_percentage'] as num) > 0;

      final product = Product(
        id: json['id'].toString(),
        name: json['product_name'] ?? json['name'] ?? '',
        description: json['description'] ?? '',
        price: json['mrp'] != null
            ? (json['mrp'] as num).toDouble()
            : json['price'] != null
                ? (json['price'] as num).toDouble()
                : 0.0,
        retailPrice: json['retail_sale_price'] != null
            ? (json['retail_sale_price'] as num).toDouble()
            : json['discounted_price'] != null
                ? (json['discounted_price'] as num).toDouble()
                : null,
        discountPercentage: json['discount_percentage'] != null
            ? (json['discount_percentage'] as num).toDouble()
            : null,
        rating: json['ratings_avg'] != null ? (json['ratings_avg'] as num).toDouble() : null,
        reviewCount: json['ratings_count'] != null ? (json['ratings_count'] as num).toInt() : null,
        mainImageUrl: imageUrl ?? 'https://via.placeholder.com/150',
        additionalImages: null, // View doesn't return additional images for performance
        inStock: json['in_stock'] == true || (json['stock_quantity'] != null && (json['stock_quantity'] as num) > 0),
        stockQuantity: json['stock_quantity'] != null ? (json['stock_quantity'] as num).toInt() : null,
        categoryId: json['category_id']?.toString() ?? '',
        subcategoryId: json['subcategory_id']?.toString(),
        brand: json['brand'],
        weight: json['weight']?.toString(),
        attributes: json['attributes'],
        nutritionalInfo: json['nutritional_info'],
        tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        onSale: isOnSale,
        categoryName: json['category_name'],
        subcategoryName: json['subcategory_name'],
        vendorId: null, // Not needed for listing
        vendorName: null, // Not needed for listing
        vendorFssaiLicense: null, // Not needed for listing
        vendorAddress: null, // Not needed for listing
        nutriActive: json['nutri_active'] ?? false,
      );

      // Convert to ProductModel
      return ProductModel.fromProduct(product);
    }).toList();
  }


  /// Get a single product by ID
  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      debugPrint('ProductSupabaseDataSource: Fetching product with ID: $id from Supabase');

      final response = await supabaseClient
          .from('products_with_images')
          .select('*')
          .eq('id', id)
          .single();

      debugPrint('ProductSupabaseDataSource: Retrieved product with ID: $id');

      // Parse the response from the view with images
      return _parseProductsResponseFromView([response]).first;
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching product: $e');
      throw ServerException(
        message: 'Failed to fetch product details from Supabase: ${e.toString()}',
      );
    }
  }

  /// Get featured products (using latest products as featured for now)
  @override
  Future<List<ProductModel>> getFeaturedProducts({
    int? limit,
  }) async {
    try {
      debugPrint('ProductSupabaseDataSource: Fetching featured products from Supabase');

      // Since is_featured column doesn't exist, use latest products as featured
      final response = await supabaseClient
          .from('products_with_images')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit ?? 10);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} featured products');

      return _parseProductsResponseFromView(response);
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

      // Get products with discounts (where retail_sale_price < mrp)
      final response = await supabaseClient
          .from('products_with_images')
          .select('*')
          .not('retail_sale_price', 'is', null)
          .not('mrp', 'is', null)
          .filter('retail_sale_price', 'lt', 'mrp')
          .order('created_at', ascending: false)
          .range(offset ?? 0, offset != null && limit != null ? offset + limit - 1 : (limit ?? 20) - 1);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} sale products');

      return _parseProductsResponseFromView(response);
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
          .from('products_with_images')
          .select('*')
          .eq('category_id', categoryId)
          .neq('id', productId)
          .order('created_at', ascending: false)
          .limit(limit ?? 4);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} related products');

      // Parse the response with images from the view
      return _parseProductsResponseFromView(response);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching related products: $e');
      throw ServerException(
        message: 'Failed to fetch related products from Supabase: ${e.toString()}',
      );
    }
  }

  /// Search products by query with robust error handling
  @override
  Future<List<ProductModel>> searchProducts({
    required String query,
    int? page,
    int? limit,
  }) async {
    try {
      debugPrint('ProductSupabaseDataSource: Searching products with query: $query (page: $page, limit: $limit)');

      // Apply pagination
      int? offset;
      if (page != null && limit != null) {
        offset = (page - 1) * limit;
        debugPrint('ProductSupabaseDataSource: Pagination - offset: $offset, limit: $limit');
      }

      // Sanitize query to prevent tsquery syntax errors
      final sanitizedQuery = _sanitizeSearchQuery(query);

      // Try multiple search strategies in order of preference
      List<dynamic> response = [];

      // Strategy 1: Try ILIKE search (most reliable for partial matches)
      try {
        response = await supabaseClient
            .from('products_with_images')
            .select('*')
            .or('name.ilike.%$sanitizedQuery%,description.ilike.%$sanitizedQuery%,brand.ilike.%$sanitizedQuery%')
            .order('created_at', ascending: false)
            .range(offset ?? 0, offset != null && limit != null ? offset + limit - 1 : 999)
            .limit(limit ?? 20);

        debugPrint('ProductSupabaseDataSource: ILIKE search found ${response.length} products');
      } catch (e) {
        debugPrint('ProductSupabaseDataSource: ILIKE search failed: $e');
      }

      // Strategy 2: If ILIKE fails or returns no results, try full-text search with proper formatting
      if (response.isEmpty && _isValidForFullTextSearch(sanitizedQuery)) {
        try {
          final formattedQuery = _formatQueryForFullTextSearch(sanitizedQuery);
          response = await supabaseClient
              .from('products_with_images')
              .select('*')
              .textSearch('name', formattedQuery, config: 'english')
              .order('created_at', ascending: false)
              .range(offset ?? 0, offset != null && limit != null ? offset + limit - 1 : 999)
              .limit(limit ?? 20);

          debugPrint('ProductSupabaseDataSource: Full-text search found ${response.length} products');
        } catch (e) {
          debugPrint('ProductSupabaseDataSource: Full-text search failed: $e');
        }
      }

      // Strategy 3: If still no results, try description search
      if (response.isEmpty) {
        try {
          response = await supabaseClient
              .from('products_with_images')
              .select('*')
              .ilike('description', '%$sanitizedQuery%')
              .order('created_at', ascending: false)
              .range(offset ?? 0, offset != null && limit != null ? offset + limit - 1 : 999)
              .limit(limit ?? 20);

          debugPrint('ProductSupabaseDataSource: Description search found ${response.length} products');
        } catch (e) {
          debugPrint('ProductSupabaseDataSource: Description search failed: $e');
        }
      }

      debugPrint('ProductSupabaseDataSource: Found ${response.length} products matching query: $query');
      return _parseProductsResponseFromView(response);

    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error searching products: $e');
      throw ServerException(
        message: 'Failed to search products from Supabase: ${e.toString()}',
      );
    }
  }

  /// Sanitize search query to prevent SQL injection and syntax errors
  String _sanitizeSearchQuery(String query) {
    // Remove special characters that can cause tsquery syntax errors
    return query
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove special chars except word chars and spaces
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();
  }

  /// Check if query is valid for full-text search
  bool _isValidForFullTextSearch(String query) {
    // Full-text search works best with complete words
    final words = query.split(' ').where((word) => word.length >= 2).toList();
    return words.isNotEmpty && words.every((word) => word.length >= 2);
  }

  /// Format query for PostgreSQL full-text search
  String _formatQueryForFullTextSearch(String query) {
    final words = query.split(' ').where((word) => word.length >= 2).toList();

    if (words.isEmpty) return query;

    // For partial words, add wildcard suffix
    final formattedWords = words.map((word) {
      // If word looks incomplete (common partial typing), add wildcard
      if (word.length < 4) {
        return '$word:*';
      }
      return word;
    }).toList();

    // Join with AND operator for better matching
    return formattedWords.join(' & ');
  }

  /// Get products by category ID
  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      debugPrint('ProductSupabaseDataSource: Fetching products for category ID: $categoryId');

      final response = await supabaseClient
          .from('products_with_images')
          .select('*')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      debugPrint('ProductSupabaseDataSource: Retrieved ${response.length} products for category ID: $categoryId');

      return _parseProductsResponseFromView(response);
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
            .from('products_with_images')
            .select('*')
            .eq('id', id);

        if (response.isNotEmpty) {
          allResults.addAll(response);
        }
      }

      debugPrint('ProductSupabaseDataSource: Retrieved ${allResults.length} products for IDs: $ids');

      return _parseProductsResponseFromView(allResults);
    } catch (e) {
      debugPrint('ProductSupabaseDataSource: Error fetching products by IDs: $e');
      throw ServerException(
        message: 'Failed to fetch products by IDs from Supabase: ${e.toString()}',
      );
    }
  }
}
