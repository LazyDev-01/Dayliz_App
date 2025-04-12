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

class ApiService {
  final SupabaseClient _supabase;

  ApiService(this._supabase);

  // GET request
  Future<ApiResponse> get(String endpoint) async {
    try {
      final response = await _supabase
          .from(endpoint.split('?')[0])
          .select();
      
      return ApiResponse(
        statusCode: 200,
        data: response,
        statusMessage: null,
      );
    } on PostgrestException catch (e) {
      return ApiResponse(
        statusCode: e.code?.startsWith('4') == true ? int.parse(e.code!) : 500,
        data: null,
        statusMessage: e.message,
      );
    } catch (e) {
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
      final response = await _supabase
          .from(endpoint.split('?')[0])
          .insert(data)
          .select();
      
      return ApiResponse(
        statusCode: 201,
        data: response,
        statusMessage: null,
      );
    } on PostgrestException catch (e) {
      return ApiResponse(
        statusCode: e.code?.startsWith('4') == true ? int.parse(e.code!) : 500,
        data: null,
        statusMessage: e.message,
      );
    } catch (e) {
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
      final response = await _supabase
          .from(endpoint.split('?')[0])
          .update(data)
          .select();
      
      return ApiResponse(
        statusCode: 200,
        data: response,
        statusMessage: null,
      );
    } on PostgrestException catch (e) {
      return ApiResponse(
        statusCode: e.code?.startsWith('4') == true ? int.parse(e.code!) : 500,
        data: null,
        statusMessage: e.message,
      );
    } catch (e) {
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
      final response = await _supabase
          .from(endpoint.split('?')[0])
          .delete()
          .select();
      
      return ApiResponse(
        statusCode: 204,
        data: response,
        statusMessage: null,
      );
    } on PostgrestException catch (e) {
      return ApiResponse(
        statusCode: e.code?.startsWith('4') == true ? int.parse(e.code!) : 500,
        data: null,
        statusMessage: e.message,
      );
    } catch (e) {
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