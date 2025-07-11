import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agent_order_model.dart';

/// Service for real-time order updates using Supabase subscriptions
class RealtimeOrdersService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _availabilityChannel;
  
  // Stream controllers for real-time updates
  final StreamController<List<AgentOrderModel>> _ordersController = 
      StreamController<List<AgentOrderModel>>.broadcast();
  final StreamController<Map<String, dynamic>> _availabilityController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _orderStatusController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<List<AgentOrderModel>> get ordersStream => _ordersController.stream;
  Stream<Map<String, dynamic>> get availabilityStream => _availabilityController.stream;
  Stream<Map<String, dynamic>> get orderStatusStream => _orderStatusController.stream;

  /// Subscribe to real-time order updates for a specific agent
  Future<void> subscribeToAgentOrders(String agentId) async {
    try {
      // Unsubscribe from previous channel if exists
      await unsubscribeFromOrders();

      // Subscribe to orders table changes for this agent
      _ordersChannel = _supabase
          .channel('agent_orders_$agentId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'delivery_agent_id',
              value: agentId,
            ),
            callback: (payload) => _handleOrderChange(payload),
          )
          .subscribe();

      print('Subscribed to real-time orders for agent: $agentId');
    } catch (e) {
      print('Error subscribing to orders: $e');
    }
  }

  /// Subscribe to agent availability updates
  Future<void> subscribeToAgentAvailability(String agentId) async {
    try {
      // Unsubscribe from previous channel if exists
      await unsubscribeFromAvailability();

      // Subscribe to agent_availability table changes
      _availabilityChannel = _supabase
          .channel('agent_availability_$agentId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'agent_availability',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'agent_id',
              value: agentId,
            ),
            callback: (payload) => _handleAvailabilityChange(payload),
          )
          .subscribe();

      print('Subscribed to real-time availability for agent: $agentId');
    } catch (e) {
      print('Error subscribing to availability: $e');
    }
  }

  /// Handle order changes from real-time subscription
  void _handleOrderChange(PostgresChangePayload payload) {
    try {
      print('Order change detected: ${payload.eventType}');
      print('Order data: ${payload.newRecord}');

      // Emit order status change for individual order updates
      final newRecord = payload.newRecord;
      if (newRecord != null) {
        _orderStatusController.add({
          'event': payload.eventType.name,
          'order_id': newRecord['id'],
          'status': newRecord['status'],
          'data': newRecord,
        });
      }

      // Trigger full orders refresh
      _refreshOrders();
    } catch (e) {
      print('Error handling order change: $e');
    }
  }

  /// Handle availability changes from real-time subscription
  void _handleAvailabilityChange(PostgresChangePayload payload) {
    try {
      print('Availability change detected: ${payload.eventType}');

      final newRecord = payload.newRecord;
      if (newRecord != null) {
        _availabilityController.add({
          'event': payload.eventType.name,
          'agent_id': newRecord['agent_id'],
          'status': newRecord['status'],
          'current_orders_count': newRecord['current_orders_count'],
          'data': newRecord,
        });
      }
    } catch (e) {
      print('Error handling availability change: $e');
    }
  }

  /// Refresh orders and emit to stream
  Future<void> _refreshOrders() async {
    try {
      // This would typically call the orders provider to refresh
      // For now, we'll emit a refresh signal
      _ordersController.add([]);
    } catch (e) {
      print('Error refreshing orders: $e');
    }
  }

  /// Unsubscribe from orders channel
  Future<void> unsubscribeFromOrders() async {
    if (_ordersChannel != null) {
      await _supabase.removeChannel(_ordersChannel!);
      _ordersChannel = null;
      print('Unsubscribed from orders channel');
    }
  }

  /// Unsubscribe from availability channel
  Future<void> unsubscribeFromAvailability() async {
    if (_availabilityChannel != null) {
      await _supabase.removeChannel(_availabilityChannel!);
      _availabilityChannel = null;
      print('Unsubscribed from availability channel');
    }
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    await unsubscribeFromOrders();
    await unsubscribeFromAvailability();
  }

  /// Send real-time notification to other agents (for order assignments)
  Future<void> broadcastOrderAssignment(String orderId, String agentId) async {
    try {
      final channel = _supabase.channel('order_assignments');

      channel.sendBroadcastMessage(
        event: 'order_assigned',
        payload: {
          'order_id': orderId,
          'agent_id': agentId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error broadcasting order assignment: $e');
    }
  }

  /// Send real-time status update notification
  Future<void> broadcastStatusUpdate(String orderId, String newStatus, String agentId) async {
    try {
      final channel = _supabase.channel('order_status_updates');

      channel.sendBroadcastMessage(
        event: 'status_updated',
        payload: {
          'order_id': orderId,
          'new_status': newStatus,
          'agent_id': agentId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error broadcasting status update: $e');
    }
  }

  /// Listen for order assignment broadcasts
  void listenForOrderAssignments(String agentId, Function(Map<String, dynamic>) onAssignment) {
    final channel = _supabase.channel('order_assignments_listener');
    
    channel.onBroadcast(
      event: 'order_assigned',
      callback: (payload) {
        if (payload['agent_id'] == agentId) {
          onAssignment(payload);
        }
      },
    ).subscribe();
  }

  /// Dispose of all resources
  void dispose() {
    unsubscribeAll();
    _ordersController.close();
    _availabilityController.close();
    _orderStatusController.close();
  }
}
