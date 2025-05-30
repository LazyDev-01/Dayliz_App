import '../models/order_model.dart';

/// Data source interface for order-related operations
abstract class OrderDataSource {
  /// Get all orders for the current user
  Future<List<OrderModel>> getOrders();
  
  /// Get an order by its ID
  Future<OrderModel> getOrderById(String orderId);
  
  /// Create a new order
  Future<OrderModel> createOrder(OrderModel order);
  
  /// Cancel an order
  Future<bool> cancelOrder(String orderId, {String? reason});
  
  /// Track an order's shipping status
  Future<Map<String, dynamic>> trackOrder(String orderId);
  
  /// Get order statistics for the current user (counts by status)
  Future<Map<String, int>> getOrderStatistics();
  
  /// Get orders by status
  Future<List<OrderModel>> getOrdersByStatus(String status);
  
  /// Search orders by query
  Future<List<OrderModel>> searchOrders(String query);
} 