import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/order.dart' as domain;
import '../errors/exceptions.dart';

/// Service for real-time order tracking and status updates
class OrderTrackingService {
  final SupabaseClient _supabase;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  OrderTrackingService({required SupabaseClient supabaseClient}) 
      : _supabase = supabaseClient;

  /// Get real-time order status updates
  Stream<Map<String, dynamic>> trackOrder(String orderId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((data) => data.isNotEmpty ? data.first : {});
  }

  /// Get order status history
  Future<List<Map<String, dynamic>>> getOrderStatusHistory(String orderId) async {
    try {
      final response = await _supabase
          .from('order_status_history')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('OrderTrackingService: Failed to get status history: $e');
      throw ServerException(message: 'Failed to get order status history');
    }
  }

  /// Update order status (for vendor/admin use)
  Future<bool> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? statusMessage,
    String? changedBy,
    String changedByType = 'system',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Update order status
      await _supabase
          .from('orders')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);

      // Insert status history
      await _supabase
          .from('order_status_history')
          .insert({
            'order_id': orderId,
            'status': newStatus,
            'status_message': statusMessage,
            'changed_by': changedBy,
            'changed_by_type': changedByType,
            'metadata': metadata ?? {},
          });

      debugPrint('OrderTrackingService: Order $orderId status updated to $newStatus');
      return true;
    } catch (e) {
      debugPrint('OrderTrackingService: Failed to update order status: $e');
      return false;
    }
  }

  /// Get estimated delivery time based on current status and weather
  Future<Map<String, dynamic>> getDeliveryEstimate(String orderId) async {
    try {
      final response = await _supabase.rpc('get_delivery_estimate', params: {
        'order_id_param': orderId,
      });

      return response ?? {
        'estimated_time': '30-45 minutes',
        'status': 'processing',
        'weather_impact': false,
      };
    } catch (e) {
      debugPrint('OrderTrackingService: Failed to get delivery estimate: $e');
      return {
        'estimated_time': '30-45 minutes',
        'status': 'processing',
        'weather_impact': false,
      };
    }
  }

  /// Check if order can be cancelled
  Future<bool> canCancelOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .single();

      final status = response['status'] as String;
      
      // Orders can be cancelled if they're still pending or confirmed
      return ['pending', 'confirmed', 'payment_pending'].contains(status);
    } catch (e) {
      debugPrint('OrderTrackingService: Failed to check cancel status: $e');
      return false;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder({
    required String orderId,
    required String reason,
    String? cancelledBy,
  }) async {
    try {
      // Check if order can be cancelled
      if (!await canCancelOrder(orderId)) {
        throw Exception('Order cannot be cancelled at this stage');
      }

      // Update order status to cancelled
      final success = await updateOrderStatus(
        orderId: orderId,
        newStatus: 'cancelled',
        statusMessage: 'Order cancelled: $reason',
        changedBy: cancelledBy,
        changedByType: 'user',
        metadata: {'cancellation_reason': reason},
      );

      if (success) {
        debugPrint('OrderTrackingService: Order $orderId cancelled successfully');
      }

      return success;
    } catch (e) {
      debugPrint('OrderTrackingService: Failed to cancel order: $e');
      return false;
    }
  }

  /// Get order tracking timeline for UI display
  Future<List<Map<String, dynamic>>> getOrderTimeline(String orderId) async {
    try {
      final statusHistory = await getOrderStatusHistory(orderId);
      
      // Convert status history to timeline format
      return statusHistory.map((status) {
        return {
          'title': _getStatusTitle(status['status']),
          'description': status['status_message'] ?? _getStatusDescription(status['status']),
          'timestamp': status['created_at'],
          'completed': true,
          'icon': _getStatusIcon(status['status']),
        };
      }).toList();
    } catch (e) {
      debugPrint('OrderTrackingService: Failed to get order timeline: $e');
      return [];
    }
  }

  /// Get user-friendly status title
  String _getStatusTitle(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Being Prepared';
      case 'ready':
        return 'Ready for Pickup';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Get user-friendly status description
  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Your order has been placed and is being processed';
      case 'confirmed':
        return 'Your order has been confirmed and will be prepared soon';
      case 'preparing':
        return 'Your items are being prepared with care';
      case 'ready':
        return 'Your order is ready and waiting for delivery';
      case 'out_for_delivery':
        return 'Your order is on the way to you';
      case 'delivered':
        return 'Your order has been delivered successfully';
      case 'cancelled':
        return 'Your order has been cancelled';
      default:
        return 'Order status updated';
    }
  }

  /// Get status icon for UI
  String _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return '📝';
      case 'confirmed':
        return '✅';
      case 'preparing':
        return '👨‍🍳';
      case 'ready':
        return '📦';
      case 'out_for_delivery':
        return '🚚';
      case 'delivered':
        return '🎉';
      case 'cancelled':
        return '❌';
      default:
        return '📋';
    }
  }
}
