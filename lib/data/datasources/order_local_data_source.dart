import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../../core/errors/exceptions.dart';
import 'order_datasource.dart';

/// Implementation of the OrderDataSource for local data operations (caching)
class OrderLocalDataSource implements OrderDataSource {
  final SharedPreferences sharedPreferences;
  
  // Keys for shared preferences
  static const String ordersKey = 'cached_orders';
  static const String orderStatisticsKey = 'cached_order_statistics';
  
  OrderLocalDataSource({required this.sharedPreferences});
  
  /// Get all orders from local cache
  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final jsonString = sharedPreferences.getString(ordersKey);
      if (jsonString != null) {
        final List<dynamic> decodedJson = json.decode(jsonString);
        return decodedJson
            .map((item) => OrderModel.fromJson(item))
            .toList();
      } else {
        throw CacheException(message: 'No cached orders found');
      }
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: 'Failed to get cached orders: ${e.toString()}');
    }
  }
  
  /// Get an order by its ID from local cache
  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final allOrders = await getOrders();
      final order = allOrders.firstWhere(
        (order) => order.id == orderId,
        orElse: () => throw NotFoundException(message: 'Order not found in cache'),
      );
      return order;
    } catch (e) {
      if (e is NotFoundException || e is CacheException) rethrow;
      throw CacheException(message: 'Failed to get cached order: ${e.toString()}');
    }
  }
  
  /// Cache a new order
  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final allOrders = await _getAllOrdersOrEmpty();
      allOrders.add(order);
      await _cacheOrders(allOrders);
      return order;
    } catch (e) {
      throw CacheException(message: 'Failed to cache new order: ${e.toString()}');
    }
  }
  
  /// Update an order's status to cancelled in the cache
  @override
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final allOrders = await _getAllOrdersOrEmpty();
      final orderIndex = allOrders.indexWhere((order) => order.id == orderId);
      
      if (orderIndex == -1) {
        throw NotFoundException(message: 'Order not found in cache');
      }
      
      // Update the order status to cancelled
      final updatedOrder = allOrders[orderIndex].copyWith(
        status: OrderModel.statusCancelled,
      );
      
      allOrders[orderIndex] = updatedOrder;
      await _cacheOrders(allOrders);
      return true;
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw CacheException(message: 'Failed to cancel cached order: ${e.toString()}');
    }
  }
  
  /// Since tracking info is real-time, this can't be meaningfully cached
  @override
  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    throw UnsupportedError('Tracking info cannot be retrieved from cache');
  }
  
  /// Get cached order statistics
  @override
  Future<Map<String, int>> getOrderStatistics() async {
    try {
      final jsonString = sharedPreferences.getString(orderStatisticsKey);
      if (jsonString != null) {
        final Map<String, dynamic> stats = json.decode(jsonString);
        return stats.map((key, value) => MapEntry(key, value as int));
      } else {
        // Calculate statistics from cached orders
        final allOrders = await _getAllOrdersOrEmpty();
        final stats = <String, int>{};
        
        // Initialize with all possible statuses
        stats[OrderModel.statusPending] = 0;
        stats[OrderModel.statusProcessing] = 0;
        stats[OrderModel.statusShipped] = 0;
        stats[OrderModel.statusDelivered] = 0;
        stats[OrderModel.statusCancelled] = 0;
        stats[OrderModel.statusRefunded] = 0;
        
        // Count orders by status
        for (final order in allOrders) {
          stats[order.status] = (stats[order.status] ?? 0) + 1;
        }
        
        // Cache the calculated statistics
        await _cacheOrderStatistics(stats);
        return stats;
      }
    } catch (e) {
      throw CacheException(message: 'Failed to get cached order statistics: ${e.toString()}');
    }
  }
  
  /// Get orders by status from cache
  @override
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      final allOrders = await _getAllOrdersOrEmpty();
      return allOrders.where((order) => order.status == status).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached orders by status: ${e.toString()}');
    }
  }
  
  /// Search orders from cache
  @override
  Future<List<OrderModel>> searchOrders(String query) async {
    if (query.isEmpty) {
      return _getAllOrdersOrEmpty();
    }
    
    try {
      final allOrders = await _getAllOrdersOrEmpty();
      final normalizedQuery = query.toLowerCase();
      
      return allOrders.where((order) {
        // Search in order ID
        if (order.id.toLowerCase().contains(normalizedQuery)) {
          return true;
        }
        
        // Search in items
        for (final item in order.items) {
          if (item.productName.toLowerCase().contains(normalizedQuery)) {
            return true;
          }
        }
        
        // Search in tracking number if available
        if (order.trackingNumber != null && 
            order.trackingNumber!.toLowerCase().contains(normalizedQuery)) {
          return true;
        }
        
        return false;
      }).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to search cached orders: ${e.toString()}');
    }
  }
  
  /// Cache a list of orders
  Future<void> cacheOrders(List<OrderModel> orders) async {
    return _cacheOrders(orders);
  }
  
  /// Helper method to cache orders
  Future<void> _cacheOrders(List<OrderModel> orders) async {
    try {
      final jsonString = json.encode(orders.map((order) => order.toJson()).toList());
      await sharedPreferences.setString(ordersKey, jsonString);
    } catch (e) {
      throw CacheException(message: 'Failed to cache orders: ${e.toString()}');
    }
  }
  
  /// Cache order statistics
  Future<void> _cacheOrderStatistics(Map<String, int> statistics) async {
    try {
      final jsonString = json.encode(statistics);
      await sharedPreferences.setString(orderStatisticsKey, jsonString);
    } catch (e) {
      throw CacheException(message: 'Failed to cache order statistics: ${e.toString()}');
    }
  }
  
  /// Helper method to get all orders or an empty list if none are cached
  Future<List<OrderModel>> _getAllOrdersOrEmpty() async {
    try {
      return await getOrders();
    } catch (e) {
      return [];
    }
  }
  
  /// Clear all cached orders
  Future<void> clearCache() async {
    await sharedPreferences.remove(ordersKey);
    await sharedPreferences.remove(orderStatisticsKey);
  }
} 