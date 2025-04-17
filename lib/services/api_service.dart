import 'package:supabase_flutter/supabase_flutter.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? statusMessage;

  ApiResponse({
    required this.statusCode,
    required this.data,
    this.statusMessage,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

// Add UUID validation
bool isValidUuid(String str) {
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return uuidRegex.hasMatch(str);
}

class ApiService {
  final SupabaseClient _supabase;

  ApiService(this._supabase);

  // GET request
  Future<ApiResponse> get(String endpoint) async {
    try {
      print("API GET request to: $endpoint");
      
      // Extract table name and query parameters
      final table = endpoint.split('?')[0];
      final queryParams = _extractQueryParams(endpoint);
      print("Querying table: $table with params: $queryParams");
      
      // Start with a base query
      var query = _supabase.from(table).select();
      
      // Apply filters if needed
      for (var param in queryParams.entries) {
        if (param.key == 'id' && param.value.startsWith('eq.')) {
          final idValue = param.value.substring(3); // Remove 'eq.'
          // Check UUID validity for ID fields to prevent DB errors
          if (!isValidUuid(idValue)) {
            print("Warning: Invalid UUID format for id parameter: $idValue");
            continue;
          }
          query = query.eq(param.key, idValue);
        } else if (param.value.startsWith('eq.')) {
          final value = param.value.substring(3); // Remove 'eq.'
          query = query.eq(param.key, value);
        } else if (param.value.startsWith('neq.')) {
          final value = param.value.substring(4); // Remove 'neq.'
          query = query.neq(param.key, value);
        }
      }
      
      // Execute the query
      final response = await query;
      
      print("API GET response from $table: ${response != null ? 'Data length: ${response.length}' : 'No data'}");
      return ApiResponse(
        statusCode: 200,
        data: response,
        statusMessage: null,
      );
    } on PostgrestException catch (e) {
      print("API GET PostgrestException for $endpoint: ${e.code} - ${e.message} - ${e.details}");
      return ApiResponse(
        statusCode: e.code?.startsWith('4') == true ? int.parse(e.code!) : 500,
        data: null,
        statusMessage: e.message,
      );
    } catch (e) {
      print("API GET error for $endpoint: $e");
      return ApiResponse(
        statusCode: 500,
        data: null,
        statusMessage: e.toString(),
      );
    }
  }

  // POST request
  Future<ApiResponse> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final table = endpoint.split('?')[0];
      print("API POST request to table: $table with data: ${data.keys.join(', ')}");
      
      // Clean data of any null values to avoid Supabase errors
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.removeWhere((key, value) => value == null);
      
      // Check if we need to handle special cases for the new schema
      if (table == 'products' && cleanData.containsKey('additional_images')) {
        return await _handleProductWithImages(cleanData);
      }
      
      print("Inserting into table: $table with clean data: ${cleanData.keys.join(', ')}");
      
      final response = await _supabase
          .from(table)
          .insert(cleanData)
          .select();
      
      print("API POST to $table successful, rows: ${response.length}");
      return ApiResponse(
        statusCode: 201,
        data: response,
        statusMessage: null,
      );
    } on PostgrestException catch (e) {
      print("API POST PostgrestException for $endpoint: ${e.code} - ${e.message} - ${e.details}");
      return ApiResponse(
        statusCode: e.code?.startsWith('4') == true ? int.parse(e.code!) : 500,
        data: null,
        statusMessage: e.message,
      );
    } catch (e) {
      print("API POST error for $endpoint: $e");
      return ApiResponse(
        statusCode: 500,
        data: null,
        statusMessage: e.toString(),
      );
    }
  }
  
  // Special handler for products with images for the new schema
  Future<ApiResponse> _handleProductWithImages(Map<String, dynamic> productData) async {
    try {
      // Extract images before inserting product
      final additionalImages = productData['additional_images'];
      final mainImageUrl = productData['image_url'];
      
      // Remove image fields from product data
      productData.remove('additional_images');
      
      // First insert the product
      final productResponse = await _supabase
          .from('products')
          .insert(productData)
          .select();
          
      if (productResponse.isEmpty) {
        throw Exception('Failed to insert product');
      }
      
      final productId = productResponse[0]['id'];
      print("Product inserted with ID: $productId");
      
      // Then insert main image as primary
      if (mainImageUrl != null) {
        await _supabase.from('product_images').insert({
          'product_id': productId,
          'image_url': mainImageUrl,
          'is_primary': true,
          'alt_text': productData['name'],
          'display_order': 0
        });
      }
      
      // Insert additional images
      if (additionalImages != null && additionalImages is List) {
        int displayOrder = 1;
        for (var imageUrl in additionalImages) {
          await _supabase.from('product_images').insert({
            'product_id': productId,
            'image_url': imageUrl,
            'is_primary': false,
            'alt_text': '${productData['name']} - alternate view',
            'display_order': displayOrder++
          });
        }
      }
      
      return ApiResponse(
        statusCode: 201,
        data: productResponse,
        statusMessage: null,
      );
    } catch (e) {
      print("Error handling product with images: $e");
      return ApiResponse(
        statusCode: 500,
        data: null,
        statusMessage: e.toString(),
      );
    }
  }

  // PATCH request
  Future<ApiResponse> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final table = endpoint.split('?')[0];
      final queryParams = _extractQueryParams(endpoint);
      print("API PATCH request to table: $table with params: $queryParams and data: ${data.keys.join(', ')}");
      
      // Clean data of any null values to avoid Supabase errors
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.removeWhere((key, value) => value == null);
      
      // Start with a base query
      var query = _supabase.from(table).update(cleanData);
      
      // Apply filters if needed
      for (var param in queryParams.entries) {
        if (param.value.startsWith('eq.')) {
          final value = param.value.substring(3); // Remove 'eq.'
          query = query.eq(param.key, value);
        } else if (param.value.startsWith('neq.')) {
          final value = param.value.substring(4); // Remove 'neq.'
          query = query.neq(param.key, value);
        }
      }
      
      // Execute the query
      final response = await query.select();
      
      print("API PATCH to $table successful, rows: ${response.length}");
      return ApiResponse(
        statusCode: 200,
        data: response,
        statusMessage: null,
      );
    } on PostgrestException catch (e) {
      print("API PATCH PostgrestException for $endpoint: ${e.code} - ${e.message} - ${e.details}");
      return ApiResponse(
        statusCode: e.code?.startsWith('4') == true ? int.parse(e.code!) : 500,
        data: null,
        statusMessage: e.message,
      );
    } catch (e) {
      print("API PATCH error for $endpoint: $e");
      return ApiResponse(
        statusCode: 500,
        data: null,
        statusMessage: e.toString(),
      );
    }
  }

  // DELETE request
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final table = endpoint.split('?')[0];
      final queryParams = _extractQueryParams(endpoint);
      print("API DELETE request to table: $table with params: $queryParams");
      
      // Start with a base query
      var query = _supabase.from(table).delete();
      
      // Apply filters if needed
      for (var param in queryParams.entries) {
        if (param.value.startsWith('eq.')) {
          final value = param.value.substring(3); // Remove 'eq.'
          query = query.eq(param.key, value);
        } else if (param.value.startsWith('neq.')) {
          final value = param.value.substring(4); // Remove 'neq.'
          query = query.neq(param.key, value);
        }
      }
      
      // Execute the query
      final response = await query.select();
      
      print("API DELETE from $table successful");
      return ApiResponse(
        statusCode: 204,
        data: response,
        statusMessage: null,
      );
    } on PostgrestException catch (e) {
      print("API DELETE PostgrestException for $endpoint: ${e.code} - ${e.message} - ${e.details}");
      return ApiResponse(
        statusCode: e.code?.startsWith('4') == true ? int.parse(e.code!) : 500,
        data: null,
        statusMessage: e.message,
      );
    } catch (e) {
      print("API DELETE error for $endpoint: $e");
      return ApiResponse(
        statusCode: 500,
        data: null,
        statusMessage: e.toString(),
      );
    }
  }

  // Helper method to extract query parameters from endpoint
  Map<String, String> _extractQueryParams(String endpoint) {
    final Map<String, String> queryParams = {};
    
    if (endpoint.contains('?')) {
      final queryString = endpoint.split('?')[1];
      final pairs = queryString.split('&');
      
      for (var pair in pairs) {
        final keyValue = pair.split('=');
        if (keyValue.length == 2) {
          queryParams[keyValue[0]] = keyValue[1];
        }
      }
    }
    
    return queryParams;
  }
} 