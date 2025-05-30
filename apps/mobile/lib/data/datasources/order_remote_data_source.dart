import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../../core/errors/exceptions.dart';
import 'order_data_source.dart';
import '../../core/constants/api_constants.dart';

/// Implementation of the OrderDataSource for remote data operations (API calls)
class OrderRemoteDataSource implements OrderDataSource {
  final http.Client client;
  final String baseUrl;

  OrderRemoteDataSource({
    required this.client,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  /// Headers for API requests
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Note: Authorization header should be added dynamically based on the current user's token
      };

  /// Add authorization token to the headers
  Map<String, String> _authorizedHeaders(String token) {
    return {
      ..._headers,
      'Authorization': 'Bearer $token',
    };
  }

  /// Get all orders for the current user
  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final token = await _getAuthToken();
      final response = await client.get(
        Uri.parse('$baseUrl/orders'),
        headers: _authorizedHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body);
        return ordersJson
            .map((json) => OrderModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to load orders',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to get orders: ${e.toString()}',
      );
    }
  }

  /// Get an order by its ID
  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final token = await _getAuthToken();
      final response = await client.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: _authorizedHeaders(token),
      );

      if (response.statusCode == 200) {
        return OrderModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Order not found');
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to load order',
        );
      }
    } catch (e) {
      if (e is NotFoundException || e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to get order: ${e.toString()}',
      );
    }
  }

  /// Create a new order
  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final token = await _getAuthToken();
      final response = await client.post(
        Uri.parse('$baseUrl/orders'),
        headers: _authorizedHeaders(token),
        body: json.encode(order.toJson()),
      );

      if (response.statusCode == 201) {
        return OrderModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to create order',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to create order: ${e.toString()}',
      );
    }
  }

  /// Cancel an order
  @override
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final token = await _getAuthToken();
      final Map<String, dynamic> payload = {'status': 'cancelled'};
      if (reason != null) {
        payload['cancel_reason'] = reason;
      }

      final response = await client.put(
        Uri.parse('$baseUrl/orders/$orderId/cancel'),
        headers: _authorizedHeaders(token),
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Order not found');
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to cancel order',
        );
      }
    } catch (e) {
      if (e is NotFoundException || e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to cancel order: ${e.toString()}',
      );
    }
  }

  /// Track an order's shipping status
  @override
  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    try {
      final token = await _getAuthToken();
      final response = await client.get(
        Uri.parse('$baseUrl/orders/$orderId/tracking'),
        headers: _authorizedHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Order not found or tracking info not available');
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to track order',
        );
      }
    } catch (e) {
      if (e is NotFoundException || e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to track order: ${e.toString()}',
      );
    }
  }

  /// Get order statistics for the current user (counts by status)
  @override
  Future<Map<String, int>> getOrderStatistics() async {
    try {
      final token = await _getAuthToken();
      final response = await client.get(
        Uri.parse('$baseUrl/orders/statistics'),
        headers: _authorizedHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> stats = json.decode(response.body);
        return stats.map((key, value) => MapEntry(key, value as int));
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to get order statistics',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to get order statistics: ${e.toString()}',
      );
    }
  }

  /// Get orders by status
  @override
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      final token = await _getAuthToken();
      final response = await client.get(
        Uri.parse('$baseUrl/orders?status=$status'),
        headers: _authorizedHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body);
        return ordersJson
            .map((json) => OrderModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to load orders by status',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to get orders by status: ${e.toString()}',
      );
    }
  }

  /// Search orders by query
  @override
  Future<List<OrderModel>> searchOrders(String query) async {
    try {
      final token = await _getAuthToken();
      final response = await client.get(
        Uri.parse('$baseUrl/orders/search?q=$query'),
        headers: _authorizedHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = json.decode(response.body);
        return ordersJson
            .map((json) => OrderModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to search orders',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to search orders: ${e.toString()}',
      );
    }
  }

  /// Helper method to get the current auth token
  Future<String> _getAuthToken() async {
    // In a real implementation, you would get this from a secure storage or auth service
    // For now, we just use a placeholder which should be replaced with actual implementation
    try {
      // This is where you'd retrieve the token from secure storage
      const token = 'placeholder-token';
      if (token.isEmpty) {
        throw UnauthorizedException(message: 'No authentication token found');
      }
      return token;
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      throw UnauthorizedException(message: 'Failed to get authentication token');
    }
  }
}