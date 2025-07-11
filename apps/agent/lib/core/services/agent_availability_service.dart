import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing agent availability and status
class AgentAvailabilityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Update agent availability status
  Future<void> updateAvailabilityStatus(String agentId, String status) async {
    await _supabase
        .from('agent_availability')
        .update({
          'status': status,
          'last_seen_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('agent_id', agentId);
  }

  /// Get agent availability info
  Future<Map<String, dynamic>?> getAgentAvailability(String agentId) async {
    try {
      final response = await _supabase
          .from('agent_availability')
          .select()
          .eq('agent_id', agentId)
          .single();

      return response;
    } catch (e) {
      // If agent availability doesn't exist, initialize it
      await _supabase.rpc('initialize_agent_availability', params: {
        'p_agent_id': agentId,
      });

      // Try again after initialization
      final response = await _supabase
          .from('agent_availability')
          .select()
          .eq('agent_id', agentId)
          .single();

      return response;
    }
  }

  /// Mark agent as available for new orders
  Future<void> goOnline(String agentId) async {
    await updateAvailabilityStatus(agentId, 'available');
  }

  /// Mark agent as offline
  Future<void> goOffline(String agentId) async {
    await updateAvailabilityStatus(agentId, 'offline');
  }

  /// Mark agent as busy
  Future<void> setBusy(String agentId) async {
    await updateAvailabilityStatus(agentId, 'busy');
  }

  /// Mark agent as on break
  Future<void> setOnBreak(String agentId) async {
    await updateAvailabilityStatus(agentId, 'on_break');
  }

  /// Update agent location
  Future<void> updateLocation(String agentId, double latitude, double longitude) async {
    await _supabase
        .from('agent_availability')
        .update({
          'last_location': {
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now().toIso8601String(),
          },
          'last_seen_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('agent_id', agentId);
  }

  /// Accept an assigned order
  Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await _supabase.rpc('update_order_status', params: {
        'order_id': orderId,
        'new_status': 'accepted',
      });
      
      return response == true;
    } catch (e) {
      print('Error accepting order: $e');
      return false;
    }
  }

  /// Update order status (picked up, out for delivery, delivered)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _supabase.rpc('update_order_status', params: {
        'order_id': orderId,
        'new_status': newStatus,
      });
      
      return response == true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  /// Get available orders for assignment (for testing)
  Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    final response = await _supabase
        .from('orders')
        .select('id, order_number, status, total_amount, created_at')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Manually assign order to agent (for testing)
  Future<String?> assignOrderToAgent(String orderId) async {
    try {
      final response = await _supabase.rpc('assign_order_to_agent', params: {
        'order_id': orderId,
      });
      
      return response as String?;
    } catch (e) {
      print('Error assigning order: $e');
      return null;
    }
  }
}
