import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_orders_service.dart';
import '../models/agent_order_model.dart';

/// State for real-time order updates
class RealtimeOrdersState {
  final List<AgentOrderModel> orders;
  final Map<String, dynamic>? latestOrderUpdate;
  final Map<String, dynamic>? latestAvailabilityUpdate;
  final bool isConnected;
  final String? error;

  const RealtimeOrdersState({
    this.orders = const [],
    this.latestOrderUpdate,
    this.latestAvailabilityUpdate,
    this.isConnected = false,
    this.error,
  });

  RealtimeOrdersState copyWith({
    List<AgentOrderModel>? orders,
    Map<String, dynamic>? latestOrderUpdate,
    Map<String, dynamic>? latestAvailabilityUpdate,
    bool? isConnected,
    String? error,
  }) {
    return RealtimeOrdersState(
      orders: orders ?? this.orders,
      latestOrderUpdate: latestOrderUpdate,
      latestAvailabilityUpdate: latestAvailabilityUpdate,
      isConnected: isConnected ?? this.isConnected,
      error: error,
    );
  }
}

/// Notifier for real-time order management
class RealtimeOrdersNotifier extends StateNotifier<RealtimeOrdersState> {
  final RealtimeOrdersService _service = RealtimeOrdersService();
  StreamSubscription<List<AgentOrderModel>>? _ordersSubscription;
  StreamSubscription<Map<String, dynamic>>? _availabilitySubscription;
  StreamSubscription<Map<String, dynamic>>? _orderStatusSubscription;
  String? _currentAgentId;

  RealtimeOrdersNotifier() : super(const RealtimeOrdersState()) {
    _initializeSubscriptions();
  }

  /// Initialize real-time subscriptions
  void _initializeSubscriptions() {
    // Listen to orders stream
    _ordersSubscription = _service.ordersStream.listen(
      (orders) {
        state = state.copyWith(orders: orders);
      },
      onError: (error) {
        state = state.copyWith(error: 'Orders stream error: $error');
      },
    );

    // Listen to availability stream
    _availabilitySubscription = _service.availabilityStream.listen(
      (availabilityUpdate) {
        state = state.copyWith(latestAvailabilityUpdate: availabilityUpdate);
      },
      onError: (error) {
        state = state.copyWith(error: 'Availability stream error: $error');
      },
    );

    // Listen to order status stream
    _orderStatusSubscription = _service.orderStatusStream.listen(
      (orderUpdate) {
        state = state.copyWith(latestOrderUpdate: orderUpdate);
      },
      onError: (error) {
        state = state.copyWith(error: 'Order status stream error: $error');
      },
    );
  }

  /// Connect to real-time updates for a specific agent
  Future<void> connectAgent(String agentId) async {
    try {
      _currentAgentId = agentId;
      
      // Subscribe to agent orders and availability
      await _service.subscribeToAgentOrders(agentId);
      await _service.subscribeToAgentAvailability(agentId);
      
      // Listen for order assignments
      _service.listenForOrderAssignments(agentId, (assignment) {
        // Handle new order assignment
        _handleNewOrderAssignment(assignment);
      });

      state = state.copyWith(isConnected: true, error: null);
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        error: 'Failed to connect: ${e.toString()}',
      );
    }
  }

  /// Handle new order assignment notification
  void _handleNewOrderAssignment(Map<String, dynamic> assignment) {
    // This could trigger a notification or UI update
    print('New order assigned: ${assignment['order_id']}');
    
    // Update state with assignment info
    state = state.copyWith(
      latestOrderUpdate: {
        'event': 'order_assigned',
        'order_id': assignment['order_id'],
        'timestamp': assignment['timestamp'],
      },
    );
  }

  /// Broadcast order status update
  Future<void> broadcastStatusUpdate(String orderId, String newStatus) async {
    if (_currentAgentId != null) {
      await _service.broadcastStatusUpdate(orderId, newStatus, _currentAgentId!);
    }
  }

  /// Broadcast order assignment
  Future<void> broadcastOrderAssignment(String orderId) async {
    if (_currentAgentId != null) {
      await _service.broadcastOrderAssignment(orderId, _currentAgentId!);
    }
  }

  /// Disconnect from real-time updates
  Future<void> disconnect() async {
    await _service.unsubscribeAll();
    state = state.copyWith(isConnected: false);
  }

  /// Clear latest updates
  void clearLatestUpdates() {
    state = state.copyWith(
      latestOrderUpdate: null,
      latestAvailabilityUpdate: null,
    );
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _availabilitySubscription?.cancel();
    _orderStatusSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}

/// Provider for real-time order management
final realtimeOrdersProvider = StateNotifierProvider<RealtimeOrdersNotifier, RealtimeOrdersState>((ref) {
  return RealtimeOrdersNotifier();
});

/// Provider for connection status
final realtimeConnectionProvider = Provider<bool>((ref) {
  return ref.watch(realtimeOrdersProvider).isConnected;
});

/// Provider for latest order update
final latestOrderUpdateProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(realtimeOrdersProvider).latestOrderUpdate;
});

/// Provider for latest availability update
final latestAvailabilityUpdateProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(realtimeOrdersProvider).latestAvailabilityUpdate;
});
