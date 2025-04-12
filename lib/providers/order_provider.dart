import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/order.dart';
import 'package:dayliz_app/services/order_service.dart';

// Order service provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

// Order state
class OrdersState {
  final List<Order> userOrders;
  final bool isLoading;
  final String? error;
  final Order? selectedOrder;

  OrdersState({
    this.userOrders = const [],
    this.isLoading = false,
    this.error,
    this.selectedOrder,
  });

  OrdersState copyWith({
    List<Order>? userOrders,
    bool? isLoading,
    String? error,
    Order? selectedOrder,
  }) {
    return OrdersState(
      userOrders: userOrders ?? this.userOrders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedOrder: selectedOrder ?? this.selectedOrder,
    );
  }
}

// Order notifier
class OrderNotifier extends StateNotifier<OrdersState> {
  final OrderService _orderService;

  OrderNotifier(this._orderService) : super(OrdersState());

  // Get user orders
  Future<void> getUserOrders(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final orders = await _orderService.getUserOrders(userId);
      state = state.copyWith(userOrders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch orders: ${e.toString()}',
      );
    }
  }

  // Get order by ID
  Future<void> getOrderById(String orderId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final order = await _orderService.getOrderById(orderId);
      state = state.copyWith(selectedOrder: order, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch order details: ${e.toString()}',
      );
    }
  }

  // Create new order
  Future<Order?> createOrder({
    required String userId,
    required List<OrderItem> items,
    required double totalAmount,
    required OrderAddress shippingAddress,
    required PaymentMethod paymentMethod,
    OrderAddress? billingAddress,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Create an Order object from the parameters
      final newOrder = Order(
        userId: userId,
        items: items,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        billingAddress: billingAddress,
        paymentMethod: paymentMethod,
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.pending,
      );
      
      final createdOrder = await _orderService.createOrder(newOrder);
      
      // Update the orders list with the new order
      final updatedOrders = [...state.userOrders, createdOrder];
      state = state.copyWith(
        userOrders: updatedOrders,
        selectedOrder: createdOrder,
        isLoading: false,
      );
      
      return createdOrder;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create order: ${e.toString()}',
      );
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final updatedOrder = await _orderService.cancelOrder(orderId, reason);
      
      // Update the order in the list
      final updatedOrders = state.userOrders.map((order) {
        return order.id == orderId ? updatedOrder : order;
      }).toList();
      
      state = state.copyWith(
        userOrders: updatedOrders,
        selectedOrder: updatedOrder,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel order: ${e.toString()}',
      );
      return false;
    }
  }

  // Clear selected order
  void clearSelectedOrder() {
    state = state.copyWith(selectedOrder: null);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final orderNotifierProvider = StateNotifierProvider<OrderNotifier, OrdersState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return OrderNotifier(orderService);
});

// Selected order provider
final selectedOrderProvider = Provider<Order?>((ref) {
  return ref.watch(orderNotifierProvider).selectedOrder;
});

// User orders provider
final userOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(orderNotifierProvider).userOrders;
});

// Order loading state provider
final orderLoadingProvider = Provider<bool>((ref) {
  return ref.watch(orderNotifierProvider).isLoading;
});

// Order error provider
final orderErrorProvider = Provider<String?>((ref) {
  return ref.watch(orderNotifierProvider).error;
});