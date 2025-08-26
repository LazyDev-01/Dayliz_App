import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/bakery_service_data_source.dart';
import '../../data/models/bakery_service_model.dart';
import '../../domain/entities/bakery_service.dart';

/// Provider for bakery service data source
final bakeryServiceDataSourceProvider = Provider<BakeryServiceDataSource>((ref) {
  final supabaseClient = Supabase.instance.client;
  return BakeryServiceSupabaseDataSource(supabaseClient: supabaseClient);
});

/// Provider for fetching all bakery services
final bakeryServicesProvider = FutureProvider<List<BakeryService>>((ref) async {
  final dataSource = ref.watch(bakeryServiceDataSourceProvider);
  return await dataSource.getBakeryServices();
});

/// Provider for fetching a specific bakery service by ID
final bakeryServiceByIdProvider = FutureProvider.family<BakeryService, String>((ref, serviceId) async {
  final dataSource = ref.watch(bakeryServiceDataSourceProvider);
  return await dataSource.getBakeryServiceById(serviceId);
});

/// Provider for fetching user's bakery orders
final userBakeryOrdersProvider = FutureProvider.family<List<BakeryOrder>, String>((ref, userId) async {
  final dataSource = ref.watch(bakeryServiceDataSourceProvider);
  return await dataSource.getUserBakeryOrders(userId);
});

/// Provider for fetching a specific bakery order by ID
final bakeryOrderByIdProvider = FutureProvider.family<BakeryOrder, String>((ref, orderId) async {
  final dataSource = ref.watch(bakeryServiceDataSourceProvider);
  return await dataSource.getBakeryOrderById(orderId);
});

/// Provider for calculating bakery price
final bakeryPriceCalculatorProvider = FutureProvider.family<double, BakeryPriceParams>((ref, params) async {
  final dataSource = ref.watch(bakeryServiceDataSourceProvider);
  return await dataSource.calculateBakeryPrice(params.serviceId, params.specifications);
});

/// Provider for fetching available bakery vendors in an area
final availableBakeryVendorsProvider = FutureProvider.family<List<BakeryVendor>, String>((ref, area) async {
  final dataSource = ref.watch(bakeryServiceDataSourceProvider);
  return await dataSource.getAvailableBakeryVendors(area);
});

/// State notifier for managing bakery order creation
class BakeryOrderNotifier extends StateNotifier<AsyncValue<BakeryOrder?>> {
  final BakeryServiceDataSource _dataSource;

  BakeryOrderNotifier(this._dataSource) : super(const AsyncValue.data(null));

  /// Create a new bakery order
  Future<void> createOrder(BakeryOrderModel order) async {
    state = const AsyncValue.loading();
    try {
      final createdOrder = await _dataSource.createBakeryOrder(order);
      state = AsyncValue.data(createdOrder);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update an existing bakery order
  Future<void> updateOrder(BakeryOrderModel order) async {
    state = const AsyncValue.loading();
    try {
      final updatedOrder = await _dataSource.updateBakeryOrder(order);
      state = AsyncValue.data(updatedOrder);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Cancel a bakery order
  Future<void> cancelOrder(String orderId) async {
    state = const AsyncValue.loading();
    try {
      final currentOrder = await _dataSource.getBakeryOrderById(orderId);
      if (currentOrder.canBeCancelled) {
        final cancelledOrder = BakeryOrderModel(
          id: currentOrder.id,
          userId: currentOrder.userId,
          serviceId: currentOrder.serviceId,
          vendorId: currentOrder.vendorId,
          deliveryAddressId: currentOrder.deliveryAddressId,
          orderType: currentOrder.orderType,
          specifications: currentOrder.specifications,
          designImages: currentOrder.designImages,
          deliveryDate: currentOrder.deliveryDate,
          deliveryTimeSlot: currentOrder.deliveryTimeSlot,
          estimatedPrice: currentOrder.estimatedPrice,
          finalPrice: currentOrder.finalPrice,
          status: BakeryOrderStatus.cancelled,
          specialInstructions: currentOrder.specialInstructions,
          vendorNotes: currentOrder.vendorNotes,
          createdAt: currentOrder.createdAt,
          updatedAt: DateTime.now(),
        );
        
        final updatedOrder = await _dataSource.updateBakeryOrder(cancelledOrder);
        state = AsyncValue.data(updatedOrder);
      } else {
        throw Exception('Order cannot be cancelled in current status');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Upload design image
  Future<String> uploadDesignImage(String filePath) async {
    try {
      return await _dataSource.uploadDesignImage(filePath);
    } catch (error) {
      rethrow;
    }
  }

  /// Reset the state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for bakery order notifier
final bakeryOrderNotifierProvider = StateNotifierProvider<BakeryOrderNotifier, AsyncValue<BakeryOrder?>>((ref) {
  final dataSource = ref.watch(bakeryServiceDataSourceProvider);
  return BakeryOrderNotifier(dataSource);
});

/// State notifier for managing bakery order form
class BakeryOrderFormNotifier extends StateNotifier<BakeryOrderFormState> {
  BakeryOrderFormNotifier() : super(BakeryOrderFormState.initial());

  /// Update selected service
  void updateService(BakeryService service) {
    state = state.copyWith(selectedService: service);
  }

  /// Update delivery address
  void updateDeliveryAddress(String addressId) {
    state = state.copyWith(deliveryAddressId: addressId);
  }

  /// Update delivery date and time
  void updateDeliveryDateTime(DateTime date, String timeSlot) {
    state = state.copyWith(
      deliveryDate: date,
      deliveryTimeSlot: timeSlot,
    );
  }

  /// Update order specifications
  void updateSpecifications(BakeryOrderSpecifications specifications) {
    state = state.copyWith(specifications: specifications);
  }

  /// Add design image
  void addDesignImage(String imageUrl) {
    final updatedImages = [...state.designImages, imageUrl];
    state = state.copyWith(designImages: updatedImages);
  }

  /// Remove design image
  void removeDesignImage(int index) {
    final updatedImages = [...state.designImages];
    updatedImages.removeAt(index);
    state = state.copyWith(designImages: updatedImages);
  }

  /// Update special instructions
  void updateSpecialInstructions(String instructions) {
    state = state.copyWith(specialInstructions: instructions);
  }

  /// Update estimated price
  void updateEstimatedPrice(double price) {
    state = state.copyWith(estimatedPrice: price);
  }

  /// Reset form
  void reset() {
    state = BakeryOrderFormState.initial();
  }

  /// Check if form is valid
  bool get isValid {
    return state.selectedService != null &&
           state.deliveryAddressId != null &&
           state.deliveryDate != null &&
           state.deliveryTimeSlot != null;
  }
}

/// Provider for bakery order form notifier
final bakeryOrderFormNotifierProvider = StateNotifierProvider<BakeryOrderFormNotifier, BakeryOrderFormState>((ref) {
  return BakeryOrderFormNotifier();
});

/// Parameters for bakery price calculation
class BakeryPriceParams {
  final String serviceId;
  final BakeryOrderSpecifications specifications;

  BakeryPriceParams({
    required this.serviceId,
    required this.specifications,
  });
}

/// State class for bakery order form
class BakeryOrderFormState {
  final BakeryService? selectedService;
  final String? deliveryAddressId;
  final DateTime? deliveryDate;
  final String? deliveryTimeSlot;
  final BakeryOrderSpecifications specifications;
  final List<String> designImages;
  final double? estimatedPrice;
  final String? specialInstructions;

  BakeryOrderFormState({
    this.selectedService,
    this.deliveryAddressId,
    this.deliveryDate,
    this.deliveryTimeSlot,
    this.specifications = const BakeryOrderSpecifications(),
    this.designImages = const [],
    this.estimatedPrice,
    this.specialInstructions,
  });

  factory BakeryOrderFormState.initial() {
    return BakeryOrderFormState();
  }

  BakeryOrderFormState copyWith({
    BakeryService? selectedService,
    String? deliveryAddressId,
    DateTime? deliveryDate,
    String? deliveryTimeSlot,
    BakeryOrderSpecifications? specifications,
    List<String>? designImages,
    double? estimatedPrice,
    String? specialInstructions,
  }) {
    return BakeryOrderFormState(
      selectedService: selectedService ?? this.selectedService,
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTimeSlot: deliveryTimeSlot ?? this.deliveryTimeSlot,
      specifications: specifications ?? this.specifications,
      designImages: designImages ?? this.designImages,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}
