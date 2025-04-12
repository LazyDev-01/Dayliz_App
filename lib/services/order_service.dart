import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dayliz_app/models/order.dart';
import 'package:dayliz_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  final SupabaseClient _supabase;
  
  factory OrderService({SupabaseClient? supabase}) {
    return _instance;
  }

  OrderService._internal() : _supabase = Supabase.instance.client;
  
  // Create a new order
  Future<Order> createOrder(Order order) async {
    try {
      final response = await _supabase
          .from('orders')
          .insert(order.toJson())
          .select('*')
          .single();
      
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }
  
  // Get all orders for a user
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, items:order_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map<Order>((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user orders: ${e.toString()}');
    }
  }
  
  // Get an order by its ID
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, items:order_items(*)')
          .eq('id', orderId)
          .single();
      
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get order: ${e.toString()}');
    }
  }
  
  // Update an order's status
  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({'status': status.value, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId)
          .select('*, items:order_items(*)')
          .single();
      
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update order status: ${e.toString()}');
    }
  }
  
  // Update payment status
  Future<Order> updatePaymentStatus(String orderId, PaymentStatus status) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({'payment_status': status.value, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId)
          .select('*, items:order_items(*)')
          .single();
      
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update payment status: ${e.toString()}');
    }
  }
  
  // Cancel an order
  Future<Order> cancelOrder(String orderId, String reason) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({
            'status': OrderStatus.cancelled.value, 
            'cancellation_reason': reason,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', orderId)
          .select('*, items:order_items(*)')
          .single();
      
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to cancel order: ${e.toString()}');
    }
  }
  
  // Process a refund
  Future<Order> processRefund(String orderId, double amount) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({
            'payment_status': PaymentStatus.refunded.value,
            'refund_amount': amount,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', orderId)
          .select('*, items:order_items(*)')
          .single();
      
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to process refund: ${e.toString()}');
    }
  }
  
  // Update tracking number
  Future<Order> updateTrackingNumber(String orderId, String trackingNumber) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({
            'tracking_number': trackingNumber,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', orderId)
          .select('*, items:order_items(*)')
          .single();
      
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update tracking number: ${e.toString()}');
    }
  }
  
  // Get order items for an order
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final response = await _supabase
          .from('order_items')
          .select('*')
          .eq('order_id', orderId);
      
      return response.map<OrderItem>((json) => OrderItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching order items: $e');
      throw Exception('Failed to fetch order items: $e');
    }
  }
  
  // Add order items in bulk
  Future<List<OrderItem>> addOrderItems(String orderId, List<OrderItem> items) async {
    try {
      final itemsJson = items.map((item) {
        final json = item.toJson();
        json['order_id'] = orderId;
        return json;
      }).toList();
      
      final response = await _supabase
          .from('order_items')
          .insert(itemsJson)
          .select();
      
      return response.map<OrderItem>((json) => OrderItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error adding order items: $e');
      throw Exception('Failed to add order items: $e');
    }
  }
  
  // Get recent orders (for admin dashboard)
  Future<List<Order>> getRecentOrders({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      
      return response.map<Order>((json) => Order.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching recent orders: $e');
      throw Exception('Failed to fetch recent orders: $e');
    }
  }
  
  // Get order statistics (for admin dashboard)
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      // Get count of orders by status
      final statusCounts = await _supabase
          .rpc('get_order_status_counts');
      
      // Get total revenue
      final revenue = await _supabase
          .rpc('get_total_revenue');
      
      return {
        'statusCounts': statusCounts,
        'totalRevenue': revenue[0]['total'] ?? 0.0,
      };
    } catch (e) {
      debugPrint('Error fetching order statistics: $e');
      throw Exception('Failed to fetch order statistics: $e');
    }
  }
} 