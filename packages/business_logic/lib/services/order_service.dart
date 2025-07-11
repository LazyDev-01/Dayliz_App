import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simplified OrderService for shared business logic
/// This service provides basic order operations that can be used across apps
class OrderService {
  final SupabaseClient _supabase;

  OrderService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      debugPrint('OrderService: Updating order $orderId to status $newStatus');
      
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add timestamp fields based on status
      switch (newStatus) {
        case 'accepted':
          updateData['accepted_at'] = DateTime.now().toIso8601String();
          break;
        case 'processing':
          updateData['accepted_at'] = DateTime.now().toIso8601String();
          break;
        case 'picked_up':
          updateData['picked_up_at'] = DateTime.now().toIso8601String();
          break;
        case 'out_for_delivery':
          updateData['ready_at'] = DateTime.now().toIso8601String();
          break;
        case 'delivered':
          updateData['delivered_at'] = DateTime.now().toIso8601String();
          break;
        case 'cancelled':
          updateData['cancelled_at'] = DateTime.now().toIso8601String();
          break;
      }

      final response = await _supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .select()
          .single();

      debugPrint('OrderService: Order status updated successfully: ${response['status']}');
      return true;
    } catch (e) {
      debugPrint('OrderService: Error updating order status: $e');
      return false;
    }
  }

  /// Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(*),
            addresses!delivery_address_id(*),
            users!user_id(*)
          ''')
          .eq('id', orderId)
          .single();

      return response;
    } catch (e) {
      debugPrint('OrderService: Error fetching order: $e');
      return null;
    }
  }

  /// Get orders for a specific agent
  Future<List<Map<String, dynamic>>> getAgentOrders(String agentId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            status,
            total_amount,
            delivery_fee,
            payment_method,
            payment_status,
            notes,
            created_at,
            updated_at,
            delivery_address_id,
            addresses!orders_delivery_address_id_fkey(recipient_name, phone_number, address_line1, address_line2, city, state, postal_code, landmark),
            order_items(product_name, product_price, quantity, total_price, image_url)
          ''')
          .eq('delivery_agent_id', agentId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('OrderService: Error fetching agent orders: $e');
      return [];
    }
  }

  /// Accept an order (for agents)
  Future<bool> acceptOrder(String orderId) async {
    return updateOrderStatus(orderId, 'accepted');
  }

  /// Mark order as picked up (for agents)
  Future<bool> markOrderPickedUp(String orderId) async {
    return updateOrderStatus(orderId, 'picked_up');
  }

  /// Mark order as out for delivery (for agents)
  Future<bool> markOrderOutForDelivery(String orderId) async {
    return updateOrderStatus(orderId, 'out_for_delivery');
  }

  /// Mark order as delivered (for agents)
  Future<bool> markOrderDelivered(String orderId) async {
    return updateOrderStatus(orderId, 'delivered');
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final updateData = <String, dynamic>{
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
        'cancelled_at': DateTime.now().toIso8601String(),
      };

      if (reason != null) {
        updateData['notes'] = 'Cancelled: $reason';
      }

      await _supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      return true;
    } catch (e) {
      debugPrint('OrderService: Error cancelling order: $e');
      return false;
    }
  }
}
