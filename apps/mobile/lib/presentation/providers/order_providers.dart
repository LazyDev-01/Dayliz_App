import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/services/order_service.dart';
import '../../domain/entities/order.dart' as domain;
import '../../domain/usecases/orders/get_orders_usecase.dart';
import '../../domain/usecases/orders/get_order_by_id_usecase.dart';
import '../../domain/usecases/orders/create_order_usecase.dart';
import '../../domain/usecases/orders/cancel_order_usecase.dart';
import '../../domain/usecases/orders/get_orders_by_status_usecase.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/datasources/order_local_data_source.dart';
import '../../core/network/network_info.dart';

// Access to the service locator
final sl = GetIt.instance;

/// Order state class to manage all order-related state
class OrdersState {
  /// List of all user's orders
  final List<domain.Order>? orders;

  /// Currently selected/viewed order
  final domain.Order? selectedOrder;

  /// Loading state
  final bool isLoading;

  /// Error message if any
  final String? errorMessage;

  /// Filter by status (if any)
  final String? statusFilter;

  /// Order tracking information (for selected order)
  final Map<String, dynamic>? trackingInfo;

  const OrdersState({
    this.orders,
    this.selectedOrder,
    this.isLoading = false,
    this.errorMessage,
    this.statusFilter,
    this.trackingInfo,
  });

  /// Create a copy of this state with modified fields
  OrdersState copyWith({
    List<domain.Order>? orders,
    domain.Order? selectedOrder,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? statusFilter,
    Map<String, dynamic>? trackingInfo,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      statusFilter: statusFilter ?? this.statusFilter,
      trackingInfo: trackingInfo ?? this.trackingInfo,
    );
  }
}

/// Order notifier class to handle order-related logic
class OrdersNotifier extends StateNotifier<OrdersState> {
  final GetOrdersUseCase _getOrdersUseCase;
  final GetOrderByIdUseCase _getOrderByIdUseCase;
  final CreateOrderUseCase _createOrderUseCase;
  final GetOrdersByStatusUseCase _getOrdersByStatusUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;

  OrdersNotifier({
    required GetOrdersUseCase getOrdersUseCase,
    required GetOrderByIdUseCase getOrderByIdUseCase,
    required CreateOrderUseCase createOrderUseCase,
    required GetOrdersByStatusUseCase getOrdersByStatusUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
  }) : _getOrdersUseCase = getOrdersUseCase,
       _getOrderByIdUseCase = getOrderByIdUseCase,
       _createOrderUseCase = createOrderUseCase,
       _getOrdersByStatusUseCase = getOrdersByStatusUseCase,
       _cancelOrderUseCase = cancelOrderUseCase,
       super(const OrdersState());

  /// Get all orders for the current user
  Future<List<domain.Order>> getOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getOrdersUseCase(NoParams());

    return result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        );
        return <domain.Order>[];
      },
      (orders) {
        state = state.copyWith(
          orders: orders,
          isLoading: false,
        );
        return orders;
      },
    );
  }

  /// Get a specific order by its ID
  Future<domain.Order?> getOrderById(String orderId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getOrderByIdUseCase(GetOrderByIdParams(orderId: orderId));

    return result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        );
        return null;
      },
      (order) {
        state = state.copyWith(
          selectedOrder: order,
          isLoading: false,
        );
        return order;
      },
    );
  }

  /// Filter orders by status
  Future<List<domain.Order>> getOrdersByStatus(String status) async {
    state = state.copyWith(isLoading: true, clearError: true, statusFilter: status);

    final result = await _getOrdersByStatusUseCase(GetOrdersByStatusParams(status: status));

    return result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        );
        return <domain.Order>[];
      },
      (orders) {
        state = state.copyWith(
          orders: orders,
          isLoading: false,
        );
        return orders;
      },
    );
  }

  /// Create a new order
  Future<Either<Failure, domain.Order>> createOrder(domain.Order order) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _createOrderUseCase(CreateOrderParams(order: order));

    result.fold(
      (failure) => state = state.copyWith(
        errorMessage: _mapFailureToMessage(failure),
        isLoading: false,
      ),
      (createdOrder) {
        // If we already have orders, add the new one to the list
        final updatedOrders = state.orders != null
            ? [...state.orders!, createdOrder]
            : [createdOrder];

        state = state.copyWith(
          orders: updatedOrders,
          selectedOrder: createdOrder,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Clear the selected order
  void clearSelectedOrder() {
    state = state.copyWith(selectedOrder: null);
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear the status filter
  void clearStatusFilter() {
    state = state.copyWith(statusFilter: null);
  }

  /// Cancel an order
  Future<Either<Failure, bool>> cancelOrder(String orderId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _cancelOrderUseCase(CancelOrderParams(orderId: orderId));

    result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: _mapFailureToMessage(failure),
          isLoading: false,
        );
      },
      (success) {
        if (success && state.orders != null) {
          // Update the order in the list to show as cancelled
          final updatedOrders = state.orders!.map((order) {
            if (order.id == orderId) {
              return order.copyWith(status: domain.Order.statusCancelled);
            }
            return order;
          }).toList();

          // If this is the currently selected order, update it too
          domain.Order? updatedSelectedOrder;
          if (state.selectedOrder != null && state.selectedOrder!.id == orderId) {
            updatedSelectedOrder = state.selectedOrder!.copyWith(
              status: domain.Order.statusCancelled
            );
          }

          state = state.copyWith(
            orders: updatedOrders,
            selectedOrder: updatedSelectedOrder ?? state.selectedOrder,
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      },
    );

    return result;
  }

  /// Map failure to user-friendly message
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error: ${failure.message}';
      case NetworkFailure:
        return 'Network error: Please check your connection';
      case NotFoundFailure:
        return 'Order not found: ${failure.message}';
      case CacheFailure:
        return 'Cache error: ${failure.message}';
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}

/// Provider for the orders notifier
final ordersNotifierProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  try {
    // Check if the required use cases are registered
    if (!sl.isRegistered<GetOrdersUseCase>()) {
      // Register order-related dependencies if they're not registered
      _registerOrderDependencies();
    }

    return OrdersNotifier(
      getOrdersUseCase: sl<GetOrdersUseCase>(),
      getOrderByIdUseCase: sl<GetOrderByIdUseCase>(),
      createOrderUseCase: sl<CreateOrderUseCase>(),
      getOrdersByStatusUseCase: sl<GetOrdersByStatusUseCase>(),
      cancelOrderUseCase: sl<CancelOrderUseCase>(),
    );
  } catch (e) {
    // If there's an error, register the dependencies and try again
    _registerOrderDependencies();

    return OrdersNotifier(
      getOrdersUseCase: sl<GetOrdersUseCase>(),
      getOrderByIdUseCase: sl<GetOrderByIdUseCase>(),
      createOrderUseCase: sl<CreateOrderUseCase>(),
      getOrdersByStatusUseCase: sl<GetOrdersByStatusUseCase>(),
      cancelOrderUseCase: sl<CancelOrderUseCase>(),
    );
  }
});

/// Provider for order loading state
final ordersLoadingProvider = Provider<bool>((ref) {
  return ref.watch(ordersNotifierProvider).isLoading;
});

/// Provider for order error message
final ordersErrorProvider = Provider<String?>((ref) {
  return ref.watch(ordersNotifierProvider).errorMessage;
});

/// Provider for the list of orders
final ordersListProvider = Provider<List<domain.Order>?>((ref) {
  return ref.watch(ordersNotifierProvider).orders;
});

/// Provider for the selected order
final selectedOrderProvider = Provider<domain.Order?>((ref) {
  return ref.watch(ordersNotifierProvider).selectedOrder;
});

/// Provider for the orders filtered by status
final statusFilterProvider = Provider<String?>((ref) {
  return ref.watch(ordersNotifierProvider).statusFilter;
});

/// Async provider for user orders - uses OrderService directly
final userOrdersProvider = FutureProvider.autoDispose<List<domain.Order>>((ref) async {
  try {
    // Create OrderService instance
    final orderService = OrderService(supabaseClient: Supabase.instance.client);

    // Get current user ID from Supabase auth
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Fetch orders using OrderService
    final orders = await orderService.getUserOrders(user.id);
    debugPrint('OrderProvider: Fetched ${orders.length} orders for user ${user.id}');

    return orders;
  } catch (e) {
    debugPrint('OrderProvider: Error fetching orders: $e');
    rethrow;
  }
});

/// Helper method to manually fetch orders
void fetchOrders(WidgetRef ref) {
  // Simply refresh the provider to trigger a new fetch
  ref.refresh(userOrdersProvider);
}

/// Async provider for order details by ID - modified to not modify state during initialization
final orderDetailProvider = FutureProvider.autoDispose.family<domain.Order?, String>((ref, orderId) async {
  // Check if we already have this order selected
  final currentOrder = ref.read(selectedOrderProvider);
  if (currentOrder != null && currentOrder.id == orderId) {
    return currentOrder;
  }

  // Return null initially, and provide a way to fetch order details manually
  return null;
});

/// Helper method to manually fetch order details
void fetchOrderDetails(WidgetRef ref, String orderId) {
  // Get the orders notifier manually
  final ordersNotifier = ref.read(ordersNotifierProvider.notifier);

  // Create a new FutureProvider that will fetch order details when called
  final _ = ref.refresh(orderDetailProvider(orderId));

  // Schedule a microtask to avoid modifying providers during build
  Future.microtask(() async {
    await ordersNotifier.getOrderById(orderId);
  });
}

/// Async provider for orders filtered by status
final ordersByStatusProvider = FutureProvider.autoDispose.family<List<domain.Order>, String>((ref, status) async {
  // Return an empty list initially
  return <domain.Order>[];
});

/// Helper method to manually fetch orders by status
void fetchOrdersByStatus(WidgetRef ref, String status) {
  // Get the orders notifier manually
  final ordersNotifier = ref.read(ordersNotifierProvider.notifier);

  // Create a new FutureProvider that will fetch orders by status when called
  final _ = ref.refresh(ordersByStatusProvider(status));

  // Schedule a microtask to avoid modifying providers during build
  Future.microtask(() async {
    await ordersNotifier.getOrdersByStatus(status);
  });
}

/// Register order-related dependencies if they're not already registered
void _registerOrderDependencies() {
  try {
    // Register OrderRepository if not already registered
    if (!sl.isRegistered<OrderRepository>()) {
      // Make sure NetworkInfo is registered
      if (!sl.isRegistered<NetworkInfo>()) {
        sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
      }

      // Register OrderRemoteDataSource if not already registered
      if (!sl.isRegistered<OrderRemoteDataSource>()) {
        sl.registerLazySingleton<OrderRemoteDataSource>(
          () => OrderRemoteDataSource(
            client: sl(),
            baseUrl: 'https://api.dayliz.com', // Use your actual API URL
          ),
        );
      }

      // Register OrderLocalDataSource if not already registered
      if (!sl.isRegistered<OrderLocalDataSource>()) {
        sl.registerLazySingleton<OrderLocalDataSource>(
          () => OrderLocalDataSource(
            sharedPreferences: sl(),
          ),
        );
      }

      // Register OrderRepository
      sl.registerLazySingleton<OrderRepository>(
        () => OrderRepositoryImpl(
          remoteDataSource: sl<OrderRemoteDataSource>(),
          localDataSource: sl<OrderLocalDataSource>(),
          networkInfo: sl<NetworkInfo>(),
        ),
      );
    }

    // Register Order Use Cases
    if (!sl.isRegistered<GetOrdersUseCase>()) {
      sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
    }

    if (!sl.isRegistered<GetOrderByIdUseCase>()) {
      sl.registerLazySingleton(() => GetOrderByIdUseCase(sl()));
    }

    if (!sl.isRegistered<CreateOrderUseCase>()) {
      sl.registerLazySingleton(() => CreateOrderUseCase(sl()));
    }

    if (!sl.isRegistered<GetOrdersByStatusUseCase>()) {
      sl.registerLazySingleton(() => GetOrdersByStatusUseCase(sl()));
    }

    if (!sl.isRegistered<CancelOrderUseCase>()) {
      sl.registerLazySingleton(() => CancelOrderUseCase(sl()));
    }

    // Order dependencies registered successfully
  } catch (e) {
    // Error registering order dependencies
    rethrow;
  }
}