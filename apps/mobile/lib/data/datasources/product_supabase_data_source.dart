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

      // Build the base query - temporarily simplified to avoid relationship issues
      var query = supabaseClient
          .from('products')
          .select('*')
          .eq('is_active', true); // Only show active products

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
      var countQuery = supabaseClient.from('products').select('id').eq('is_active', true);

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

      final products = _parseProductsResponse(response);
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

      // Start building the query - temporarily simplified to avoid relationship issues
      var query = supabaseClient
          .from('products')
          .select('*')
          .eq('is_active', true); // Only show active products

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
      // Use main_image_url from products table directly
      String? imageUrl = json['main_image_url'];

      // Use category and subcategory names from products table directly
      String? categoryName = json['category_name'];
      String? subcategoryName = json['subcategory_name'];

      // Create a ProductModel from the JSON data
      final isOnSale = json['discount_percentage'] != null && (json['discount_percentage'] as num) > 0;

      // Create a Product entity first
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
            : null,
        discountPercentage: json['discount_percentage'] != null
            ? (json['discount_percentage'] as num).toDouble()
            : null,
        rating: json['ratings_avg'] != null ? (json['ratings_avg'] as num).toDouble() : null,
        reviewCount: json['ratings_count'] != null ? (json['ratings_count'] as num).toInt() : null,
        mainImageUrl: imageUrl ?? 'https://via.placeholder.com/150',
        additionalImages: json['additional_images'] != null
            ? List<String>.from(json['additional_images'])
            : null,
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
        categoryName: categoryName,
        subcategoryName: subcategoryName,
        vendorId: json['vendor_id'],
        vendorName: json['vendor_name'],
        vendorFssaiLicense: json['vendor_fssai_license'],
        vendorAddress: json['vendor_address'],
        nutriActive: json['nutri_active'] ?? false,
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

  /// Parse a single product response with vendor information
  ProductModel _parseProductResponseWithoutImages(Map<String, dynamic> json) {
    // Vendor information will be null for now
    // This can be enhanced later with a separate vendor data fetching mechanism
    String? vendorId;
    String? vendorName;
    String? vendorFssaiLicense;
    String? vendorAddress;

    // Create a Product entity with vendor information
    final product = Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['mrp'] != null
          ? (json['mrp'] as num).toDouble()
          : json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      retailPrice: json['retail_sale_price'] != null
          ? (json['retail_sale_price'] as num).toDouble()
          : null,
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
      weight: json['weight']?.toString(),
      attributes: json['attributes'],
      nutritionalInfo: json['nutritional_info'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      onSale: json['discount_percentage'] != null && (json['discount_percentage'] as num) > 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      vendorId: vendorId,
      vendorName: vendorName,
      vendorFssaiLicense: vendorFssaiLicense,
      vendorAddress: vendorAddress,
      nutriActive: json['nutri_active'] ?? false,
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
          .eq('is_active', true) // Only show active products
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
            .from('products')
            .select('*')
            .eq('is_active', true) // Only show active products
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
              .from('products')
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
              .from('products')
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
      return _parseProductsResponse(response);

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
          .from('products')
          .select('*')
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
            .select('*')
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
