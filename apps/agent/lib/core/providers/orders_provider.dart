import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agent_order_model.dart';
import '../services/agent_availability_service.dart';

/// State class for agent orders
class AgentOrdersState {
  final List<AgentOrderModel> orders;
  final bool isLoading;
  final String? error;
  final Map<String, int> stats;

  const AgentOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.stats = const {},
  });

  AgentOrdersState copyWith({
    List<AgentOrderModel>? orders,
    bool? isLoading,
    String? error,
    Map<String, int>? stats,
  }) {
    return AgentOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

/// Provider for managing agent orders
class AgentOrdersNotifier extends StateNotifier<AgentOrdersState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AgentAvailabilityService _availabilityService = AgentAvailabilityService();

  AgentOrdersNotifier() : super(const AgentOrdersState());

  /// Fetch orders assigned to the current agent
  Future<void> fetchAgentOrders(String agentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Query orders with all related data in one call
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

      // Convert to AgentOrderModel objects
      final orders = (response as List<dynamic>)
          .map((orderData) => AgentOrderModel.fromDatabaseJson(orderData))
          .toList();

      // Calculate stats
      final stats = _calculateStats(orders);

      state = state.copyWith(
        orders: orders,
        isLoading: false,
        stats: stats,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch orders: ${e.toString()}',
      );
    }
  }

  /// Fetch a single order by ID
  Future<AgentOrderModel?> fetchOrderById(String orderId) async {
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
          .eq('id', orderId)
          .single();

      return AgentOrderModel.fromDatabaseJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Calculate order statistics
  Map<String, int> _calculateStats(List<AgentOrderModel> orders) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayOrders = orders.where((order) {
      return order.createdAt.isAfter(todayStart) && 
             order.createdAt.isBefore(todayEnd);
    }).toList();

    final completedToday = todayOrders.where((order) {
      return order.status == 'delivered';
    }).length;

    final totalEarnings = todayOrders
        .where((order) => order.status == 'delivered')
        .fold(0.0, (sum, order) => sum + order.deliveryFee)
        .round();

    return {
      'todayOrders': todayOrders.length,
      'completedToday': completedToday,
      'todayEarnings': totalEarnings,
    };
  }

  /// Update order status using the availability service
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Use the availability service which handles agent capacity updates
      final success = await _availabilityService.updateOrderStatus(orderId, newStatus);

      if (success) {
        // Refresh orders after successful update
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          // Get agent ID from agents table
          final agentResponse = await _supabase
              .from('agents')
              .select('id')
              .eq('user_id', currentUser.id)
              .single();

          await fetchAgentOrders(agentResponse['id']);
        }
      } else {
        state = state.copyWith(
          error: 'Failed to update order status',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update order status: ${e.toString()}',
      );
    }
  }

  /// Accept an assigned order
  Future<void> acceptOrder(String orderId) async {
    await updateOrderStatus(orderId, 'accepted');
  }

  /// Mark order as picked up
  Future<void> markOrderPickedUp(String orderId) async {
    await updateOrderStatus(orderId, 'picked_up');
  }

  /// Mark order as out for delivery
  Future<void> markOrderOutForDelivery(String orderId) async {
    await updateOrderStatus(orderId, 'out_for_delivery');
  }

  /// Mark order as delivered
  Future<void> markOrderDelivered(String orderId) async {
    await updateOrderStatus(orderId, 'delivered');
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, 'cancelled');
  }

  /// Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Get agent data from user ID
  Future<Map<String, dynamic>?> getAgentFromUser(String userId) async {
    try {
      final response = await _supabase
          .from('agents')
          .select('id, agent_id, full_name')
          .eq('user_id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Refresh orders
  Future<void> refreshOrders() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      try {
        final agentResponse = await _supabase
            .from('agents')
            .select('id')
            .eq('user_id', currentUser.id)
            .single();

        await fetchAgentOrders(agentResponse['id']);
      } catch (e) {
        state = state.copyWith(
          error: 'Failed to refresh orders: ${e.toString()}',
        );
      }
    }
  }
}

/// Provider for agent orders
final agentOrdersProvider = StateNotifierProvider<AgentOrdersNotifier, AgentOrdersState>((ref) {
  return AgentOrdersNotifier();
});

/// Provider for orders filtered by status
final ordersByStatusProvider = Provider.family<List<AgentOrderModel>, String>((ref, status) {
  final ordersState = ref.watch(agentOrdersProvider);
  return ordersState.orders.where((order) => order.status == status).toList();
});

/// Provider for today's order statistics
final todayStatsProvider = Provider<Map<String, int>>((ref) {
  final ordersState = ref.watch(agentOrdersProvider);
  return ordersState.stats;
});
