import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/usecases/usecase.dart';
import 'package:dayliz_app/domain/entities/order.dart' as domain;
import 'package:dayliz_app/domain/entities/address.dart';
import 'package:dayliz_app/domain/entities/order_item.dart';
import 'package:dayliz_app/domain/entities/payment_method.dart';
import 'package:dayliz_app/domain/usecases/orders/get_orders_usecase.dart';
import 'package:dayliz_app/domain/usecases/orders/get_order_by_id_usecase.dart';
import 'package:dayliz_app/domain/usecases/orders/create_order_usecase.dart';
import 'package:dayliz_app/domain/usecases/orders/cancel_order_usecase.dart';
import 'package:dayliz_app/domain/usecases/orders/get_orders_by_status_usecase.dart';
import 'package:dayliz_app/presentation/providers/order_providers.dart';

// Manual mock classes
class MockGetOrdersUseCase extends Mock implements GetOrdersUseCase {}
class MockGetOrderByIdUseCase extends Mock implements GetOrderByIdUseCase {}
class MockCreateOrderUseCase extends Mock implements CreateOrderUseCase {}
class MockCancelOrderUseCase extends Mock implements CancelOrderUseCase {}
class MockGetOrdersByStatusUseCase extends Mock implements GetOrdersByStatusUseCase {}

void main() {
  late MockGetOrdersUseCase mockGetOrdersUseCase;
  late MockGetOrderByIdUseCase mockGetOrderByIdUseCase;
  late MockCreateOrderUseCase mockCreateOrderUseCase;
  late MockCancelOrderUseCase mockCancelOrderUseCase;
  late MockGetOrdersByStatusUseCase mockGetOrdersByStatusUseCase;

  setUp(() {
    mockGetOrdersUseCase = MockGetOrdersUseCase();
    mockGetOrderByIdUseCase = MockGetOrderByIdUseCase();
    mockCreateOrderUseCase = MockCreateOrderUseCase();
    mockCancelOrderUseCase = MockCancelOrderUseCase();
    mockGetOrdersByStatusUseCase = MockGetOrdersByStatusUseCase();
  });

  const tUserId = 'test-user-id';
  const tOrderId = 'test-order-id';
  const tStatus = 'pending';
  const tReason = 'Changed mind';

  final tAddress = Address(
    id: 'address-id',
    userId: tUserId,
    addressLine1: 'Test Address',
    city: 'Test City',
    state: 'Test State',
    postalCode: '12345',
    country: 'Test Country',
    addressType: 'Home',
  );

  const tPaymentMethod = PaymentMethod(
    id: 'payment-id',
    type: 'credit_card',
    cardNumber: '**** **** **** 1234',
    expiryDate: '12/25',
    cardHolderName: 'Test User',
    isDefault: true,
  );

  final tOrderItem = OrderItem(
    id: 'item-id',
    productId: 'product-id',
    productName: 'Test Product',
    quantity: 2,
    price: 99.99,
    total: 199.98,
    imageUrl: 'https://example.com/image.jpg',
  );

  final tOrder = domain.Order(
    id: tOrderId,
    userId: tUserId,
    items: [tOrderItem],
    subtotal: 199.98,
    tax: 20.00,
    shipping: 10.00,
    total: 229.98,
    status: tStatus,
    createdAt: DateTime.now(),
    shippingAddress: tAddress,
    paymentMethod: tPaymentMethod,
  );

  final tOrders = [tOrder];

  group('OrdersNotifier', () {
    late OrdersNotifier notifier;

    setUp(() {
      notifier = OrdersNotifier(
        getOrdersUseCase: mockGetOrdersUseCase,
        getOrderByIdUseCase: mockGetOrderByIdUseCase,
        createOrderUseCase: mockCreateOrderUseCase,
        cancelOrderUseCase: mockCancelOrderUseCase,
        getOrdersByStatusUseCase: mockGetOrdersByStatusUseCase,
      );
    });

    test('initial state should have empty orders', () {
      expect(notifier.state.orders, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('should get orders successfully', () async {
      // arrange
      when(mockGetOrdersUseCase.call(any))
          .thenAnswer((_) async => Right(tOrders));

      // act
      await notifier.getOrders();

      // assert
      expect(notifier.state.orders, tOrders);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetOrdersUseCase.call(NoParams()));
    });

    test('should handle error when getting orders fails', () async {
      // arrange
      when(mockGetOrdersUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

      // act
      await notifier.getOrders();

      // assert
      expect(notifier.state.orders, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, 'Server error');
      verify(mockGetOrdersUseCase.call(NoParams()));
    });

    test('should get order by id successfully', () async {
      // arrange
      when(mockGetOrderByIdUseCase.call(any))
          .thenAnswer((_) async => Right(tOrder));

      // act
      final result = await notifier.getOrderById(tOrderId);

      // assert
      expect(result, tOrder);
      verify(mockGetOrderByIdUseCase.call(GetOrderByIdParams(orderId: tOrderId)));
    });

    test('should handle error when getting order by id fails', () async {
      // arrange
      when(mockGetOrderByIdUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Order not found')));

      // act
      final result = await notifier.getOrderById(tOrderId);

      // assert
      expect(result, isNull);
      expect(notifier.state.errorMessage, 'Order not found');
      verify(mockGetOrderByIdUseCase.call(GetOrderByIdParams(orderId: tOrderId)));
    });

    test('should create order successfully', () async {
      // arrange
      when(mockCreateOrderUseCase.call(any))
          .thenAnswer((_) async => Right(tOrder));
      when(mockGetOrdersUseCase.call(any))
          .thenAnswer((_) async => Right(tOrders));

      // act
      final result = await notifier.createOrder(tOrder);

      // assert
      expect(result, tOrder);
      expect(notifier.state.orders, tOrders);
      verify(mockCreateOrderUseCase.call(CreateOrderParams(order: tOrder)));
      verify(mockGetOrdersUseCase.call(NoParams()));
    });

    test('should handle error when creating order fails', () async {
      // arrange
      when(mockCreateOrderUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to create order')));

      // act
      final result = await notifier.createOrder(tOrder);

      // assert
      expect(result, isNull);
      expect(notifier.state.errorMessage, 'Failed to create order');
      verify(mockCreateOrderUseCase.call(CreateOrderParams(order: tOrder)));
    });

    test('should cancel order successfully', () async {
      // arrange
      when(mockCancelOrderUseCase.call(any))
          .thenAnswer((_) async => const Right(true));
      when(mockGetOrdersUseCase.call(any))
          .thenAnswer((_) async => Right(tOrders));

      // act
      final result = await notifier.cancelOrder(tOrderId, reason: tReason);

      // assert
      expect(result, true);
      verify(mockCancelOrderUseCase.call(CancelOrderParams(orderId: tOrderId, reason: tReason)));
      verify(mockGetOrdersUseCase.call(NoParams()));
    });

    test('should handle error when canceling order fails', () async {
      // arrange
      when(mockCancelOrderUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to cancel order')));

      // act
      final result = await notifier.cancelOrder(tOrderId, reason: tReason);

      // assert
      expect(result, false);
      expect(notifier.state.errorMessage, 'Failed to cancel order');
      verify(mockCancelOrderUseCase.call(CancelOrderParams(orderId: tOrderId, reason: tReason)));
    });

    test('should get orders by status successfully', () async {
      // arrange
      when(mockGetOrdersByStatusUseCase.call(any))
          .thenAnswer((_) async => Right(tOrders));

      // act
      await notifier.getOrdersByStatus(tStatus);

      // assert
      expect(notifier.state.orders, tOrders);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetOrdersByStatusUseCase.call(GetOrdersByStatusParams(status: tStatus)));
    });

    test('should handle error when getting orders by status fails', () async {
      // arrange
      when(mockGetOrdersByStatusUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to get orders by status')));

      // act
      await notifier.getOrdersByStatus(tStatus);

      // assert
      expect(notifier.state.orders, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, 'Failed to get orders by status');
      verify(mockGetOrdersByStatusUseCase.call(GetOrdersByStatusParams(status: tStatus)));
    });

    test('should refresh orders successfully', () async {
      // arrange
      when(mockGetOrdersUseCase.call(any))
          .thenAnswer((_) async => Right(tOrders));

      // act
      await notifier.refreshOrders();

      // assert
      expect(notifier.state.orders, tOrders);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetOrdersUseCase.call(NoParams()));
    });

    test('should clear error message', () async {
      // arrange - first create an error
      when(mockGetOrdersUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));
      await notifier.getOrders();

      // act
      notifier.clearError();

      // assert
      expect(notifier.state.errorMessage, isNull);
    });

    test('should filter orders by status locally', () async {
      // arrange
      final tPendingOrder = tOrder.copyWith(status: 'pending');
      final tProcessingOrder = tOrder.copyWith(status: 'processing', id: 'order-2');
      final tDeliveredOrder = tOrder.copyWith(status: 'delivered', id: 'order-3');
      final tAllOrders = [tPendingOrder, tProcessingOrder, tDeliveredOrder];

      when(mockGetOrdersUseCase.call(any))
          .thenAnswer((_) async => Right(tAllOrders));
      await notifier.getOrders();

      // act
      final pendingOrders = notifier.getOrdersByStatusLocal('pending');
      final processingOrders = notifier.getOrdersByStatusLocal('processing');
      final deliveredOrders = notifier.getOrdersByStatusLocal('delivered');

      // assert
      expect(pendingOrders.length, 1);
      expect(pendingOrders[0].status, 'pending');
      expect(processingOrders.length, 1);
      expect(processingOrders[0].status, 'processing');
      expect(deliveredOrders.length, 1);
      expect(deliveredOrders[0].status, 'delivered');
    });
  });
}
