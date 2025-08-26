import 'dart:async';
import 'dart:developer' as developer;
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

      developer.log('Subscribed to real-time orders for agent: $agentId', name: 'RealtimeOrdersService');
    } catch (e) {
      developer.log('Error subscribing to orders: $e', name: 'RealtimeOrdersService', error: e);
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

      developer.log('Subscribed to real-time availability for agent: $agentId', name: 'RealtimeOrdersService');
    } catch (e) {
      developer.log('Error subscribing to availability: $e', name: 'RealtimeOrdersService', error: e);
    }
  }

  /// Handle order changes from real-time subscription
  void _handleOrderChange(PostgresChangePayload payload) {
    try {
      developer.log('Order change detected: ${payload.eventType}', name: 'RealtimeOrdersService');
      developer.log('Order data: ${payload.newRecord}', name: 'RealtimeOrdersService');

      // Emit order status change for individual order updates
      final newRecord = payload.newRecord;
      _orderStatusController.add({
        'event': payload.eventType.name,
        'order_id': newRecord['id'],
        'status': newRecord['status'],
        'data': newRecord,
      });

      // Trigger full orders refresh
      _refreshOrders();
    } catch (e) {
      developer.log('Error handling order change: $e', name: 'RealtimeOrdersService', error: e);
    }
  }

  /// Handle availability changes from real-time subscription
  void _handleAvailabilityChange(PostgresChangePayload payload) {
    try {
      developer.log('Availability change detected: ${payload.eventType}', name: 'RealtimeOrdersService');

      final newRecord = payload.newRecord;
      _availabilityController.add({
        'event': payload.eventType.name,
        'agent_id': newRecord['agent_id'],
        'status': newRecord['status'],
        'current_orders_count': newRecord['current_orders_count'],
        'data': newRecord,
      });
    } catch (e) {
      developer.log('Error handling availability change: $e', name: 'RealtimeOrdersService', error: e);
    }
  }

  /// Refresh orders and emit to stream
  Future<void> _refreshOrders() async {
    try {
      // This would typically call the orders provider to refresh
      // For now, we'll emit a refresh signal
      _ordersController.add([]);
    } catch (e) {
      developer.log('Error refreshing orders: $e', name: 'RealtimeOrdersService', error: e);
    }
  }

  /// Unsubscribe from orders channel
  Future<void> unsubscribeFromOrders() async {
    if (_ordersChannel != null) {
      await _supabase.removeChannel(_ordersChannel!);
      _ordersChannel = null;
      developer.log('Unsubscribed from orders channel', name: 'RealtimeOrdersService');
    }
  }

  /// Unsubscribe from availability channel
  Future<void> unsubscribeFromAvailability() async {
    if (_availabilityChannel != null) {
      await _supabase.removeChannel(_availabilityChannel!);
      _availabilityChannel = null;
      developer.log('Unsubscribed from availability channel', name: 'RealtimeOrdersService');
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
      developer.log('Error broadcasting order assignment: $e', name: 'RealtimeOrdersService', error: e);
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
      developer.log('Error broadcasting status update: $e', name: 'RealtimeOrdersService', error: e);
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
