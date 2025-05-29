import 'package:dayliz_app/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      print('🔍 Fetching all products from Supabase');
      
      final response = await _supabase
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
          .order('created_at', ascending: false);
      
      print('📊 Retrieved ${response.length} products from database');
      
      return _parseProductsResponse(response);
    } catch (e) {
      print('❌ Error fetching products: $e');
      rethrow;
    }
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts() async {
    try {
      print('🔍 Fetching featured products from Supabase');
      
      final response = await _supabase
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
          .eq('is_featured', true)
          .order('created_at', ascending: false);
      
      print('📊 Retrieved ${response.length} featured products from database');
      
      return _parseProductsResponse(response);
    } catch (e) {
      print('❌ Error fetching featured products: $e');
      rethrow;
    }
  }

  // Get sale products
  Future<List<Product>> getSaleProducts() async {
    try {
      print('🔍 Fetching sale products from Supabase');
      
      final response = await _supabase
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
          .eq('is_on_sale', true)
          .order('created_at', ascending: false);
      
      print('📊 Retrieved ${response.length} sale products from database');
      
      return _parseProductsResponse(response);
    } catch (e) {
      print('❌ Error fetching sale products: $e');
      rethrow;
    }
  }

  // Get products by category ID
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      print('🔍 Fetching products for category $categoryId');
      
      final response = await _supabase
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);
      
      print('📊 Retrieved ${response.length} products for category $categoryId');
      
      return _parseProductsResponse(response);
    } catch (e) {
      print('❌ Error fetching products by category: $e');
      rethrow;
    }
  }

  // Get products by subcategory ID
  Future<List<Product>> getProductsBySubcategory(String subcategoryId) async {
    try {
      print('🔍 Fetching products for subcategory $subcategoryId');
      
      final response = await _supabase
          .from('products')
          .select('*, product_images(image_url, is_primary), subcategories(name), categories(name)')
          .eq('subcategory_id', subcategoryId)
          .order('created_at', ascending: false);
      
      print('📊 Retrieved ${response.length} products for subcategory $subcategoryId');
      
      return _parseProductsResponse(response);
    } catch (e) {
      print('❌ Error fetching products by subcategory: $e');
      rethrow;
    }
  }

  // Helper method to parse product response
  List<Product> _parseProductsResponse(List<dynamic> response) {
    return response.map((json) {
      // Get the primary image or the first image
      String imageUrl = 'https://placehold.co/400/4CAF50/FFFFFF?text=No+Image';
      if (json['product_images'] != null && json['product_images'].isNotEmpty) {
        // Find primary image first
        final primaryImage = json['product_images'].firstWhere(
          (img) => img['is_primary'] == true, 
          orElse: () => json['product_images'][0]
        );
        
        if (primaryImage != null && primaryImage['image_url'] != null) {
          imageUrl = primaryImage['image_url'];
        }
      }
      
      // Get categories
      List<String> categories = [];
      if (json['categories'] != null && json['categories']['name'] != null) {
        categories.add(json['categories']['name']);
      }
      if (json['subcategories'] != null && json['subcategories']['name'] != null) {
        categories.add(json['subcategories']['name']);
      }
      
      // Default values for missing fields
      final rating = (json['ratings_avg'] is num) ? (json['ratings_avg'] as num).toDouble() : 0.0;
      final reviewCount = (json['ratings_count'] is num) ? (json['ratings_count'] as num).toInt() : 0;
      
      return Product(
        id: json['id'].toString(),
        name: json['name'] as String,
        description: json['description'] ?? '',
        price: (json['price'] as num).toDouble(),
        discountPrice: json['discounted_price'] != null 
            ? (json['discounted_price'] as num).toDouble() 
            : null,
        imageUrl: imageUrl,
        additionalImages: _getAdditionalImages(json['product_images'] ?? []),
        isInStock: json['stock_quantity'] != null ? (json['stock_quantity'] as num) > 0 : false,
        stockQuantity: json['stock_quantity'] != null ? (json['stock_quantity'] as num).toInt() : 0,
        categories: categories,
        categoryId: json['category_id']?.toString(),
        rating: rating,
        reviewCount: reviewCount,
        brand: json['vendor_id'] != null ? 'Dayliz Store' : 'Unknown',
        dateAdded: json['created_at'] != null 
            ? DateTime.parse(json['created_at']) 
            : DateTime.now(),
        attributes: {},
        isFeatured: json['is_featured'] == true,
        isOnSale: json['is_on_sale'] == true,
      );
    }).toList();
  }
  
  // Helper to extract additional images
  List<String> _getAdditionalImages(List<dynamic> images) {
    if (images.isEmpty) return [];
    
    return images
        .where((img) => img['is_primary'] != true && img['image_url'] != null)
        .map<String>((img) => img['image_url'] as String)
        .toList();
  }
  
  // Search products by query
  Future<List<Product>> searchProducts(String query) async {
    try {
      print('🔍 Searching for products with query: $query');
      
      // First try to get all products
      final allProducts = await getAllProducts();
      
      // Filter products based on search query
      final searchTerms = query.toLowerCase().split(' ');
      
      return allProducts.where((product) {
        final name = product.name.toLowerCase();
        final description = product.description.toLowerCase();
        final brand = product.brand.toLowerCase();
        final categories = product.categories.join(' ').toLowerCase();
        
        // Check if any search term is in the product details
        return searchTerms.any((term) => 
          name.contains(term) || 
          description.contains(term) ||
          brand.contains(term) ||
          categories.contains(term)
        );
      }).toList();
    } catch (e) {
      print('❌ Error searching products: $e');
      rethrow;
    }
  }
} 