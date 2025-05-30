import 'package:dartz/dartz.dart';
import '../entities/order.dart' as domain;
import '../../core/errors/failures.dart';

/// Repository interface for order-related operations
abstract class OrderRepository {
  /// Get all orders for the current user
  Future<Either<Failure, List<domain.Order>>> getOrders();
  
  /// Get an order by its ID
  Future<Either<Failure, domain.Order>> getOrderById(String orderId);
  
  /// Create a new order
  Future<Either<Failure, domain.Order>> createOrder(domain.Order order);
  
  /// Cancel an order
  Future<Either<Failure, bool>> cancelOrder(String orderId, {String? reason});
  
  /// Track an order's shipping status
  Future<Either<Failure, Map<String, dynamic>>> trackOrder(String orderId);
  
  /// Get order statistics for the current user (counts by status)
  Future<Either<Failure, Map<String, int>>> getOrderStatistics();
  
  /// Get orders by status
  Future<Either<Failure, List<domain.Order>>> getOrdersByStatus(String status);
  
  /// Search orders by query
  Future<Either<Failure, List<domain.Order>>> searchOrders(String query);
} 