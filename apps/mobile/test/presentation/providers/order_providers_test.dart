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

  const tAddress = Address(
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
    userId: tUserId,
    type: 'credit_card',
    name: 'Test Credit Card',
    isDefault: true,
    details: {
      'cardNumber': '**** **** **** 1234',
      'expiryDate': '12/25',
      'cardHolderName': 'Test User',
      'last4': '1234',
      'brand': 'visa',
    },
  );

  const tOrderItem = OrderItem(
    id: 'item-id',
    productId: 'product-id',
    productName: 'Test Product',
    quantity: 2,
    unitPrice: 99.99,
    totalPrice: 199.98,
    imageUrl: 'https://example.com/image.jpg',
  );

  final tOrder = domain.Order(
    id: tOrderId,
    userId: tUserId,
    items: const [tOrderItem],
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

    test('initial state should have null orders', () {
      expect(notifier.state.orders, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('should get orders successfully', () async {
      // arrange
      when(mockGetOrdersUseCase.call(NoParams()))
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
      when(mockGetOrdersUseCase.call(NoParams()))
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
      when(mockGetOrderByIdUseCase.call(const GetOrderByIdParams(orderId: tOrderId)))
          .thenAnswer((_) async => Right(tOrder));

      // act
      final result = await notifier.getOrderById(tOrderId);

      // assert
      expect(result, tOrder);
      verify(mockGetOrderByIdUseCase.call(const GetOrderByIdParams(orderId: tOrderId)));
    });

    test('should handle error when getting order by id fails', () async {
      // arrange
      when(mockGetOrderByIdUseCase.call(const GetOrderByIdParams(orderId: tOrderId)))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Order not found')));

      // act
      final result = await notifier.getOrderById(tOrderId);

      // assert
      expect(result, isNull);
      expect(notifier.state.errorMessage, 'Order not found');
      verify(mockGetOrderByIdUseCase.call(const GetOrderByIdParams(orderId: tOrderId)));
    });

    test('should create order successfully', () async {
      // arrange
      when(mockCreateOrderUseCase.call(CreateOrderParams(order: tOrder)))
          .thenAnswer((_) async => Right(tOrder));
      when(mockGetOrdersUseCase.call(NoParams()))
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
      when(mockCreateOrderUseCase.call(CreateOrderParams(order: tOrder)))
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
      when(mockCancelOrderUseCase.call(const CancelOrderParams(orderId: tOrderId)))
          .thenAnswer((_) async => const Right(true));

      // act
      final result = await notifier.cancelOrder(tOrderId);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure'),
        (success) => expect(success, true),
      );
      verify(mockCancelOrderUseCase.call(const CancelOrderParams(orderId: tOrderId)));
    });

    test('should handle error when canceling order fails', () async {
      // arrange
      when(mockCancelOrderUseCase.call(const CancelOrderParams(orderId: tOrderId)))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to cancel order')));

      // act
      final result = await notifier.cancelOrder(tOrderId);

      // assert
      expect(result.isLeft(), true);
      expect(notifier.state.errorMessage, 'Failed to cancel order');
      verify(mockCancelOrderUseCase.call(const CancelOrderParams(orderId: tOrderId)));
    });

    test('should get orders by status successfully', () async {
      // arrange
      when(mockGetOrdersByStatusUseCase.call(const GetOrdersByStatusParams(status: tStatus)))
          .thenAnswer((_) async => Right(tOrders));

      // act
      await notifier.getOrdersByStatus(tStatus);

      // assert
      expect(notifier.state.orders, tOrders);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetOrdersByStatusUseCase.call(const GetOrdersByStatusParams(status: tStatus)));
    });

    test('should handle error when getting orders by status fails', () async {
      // arrange
      when(mockGetOrdersByStatusUseCase.call(const GetOrdersByStatusParams(status: tStatus)))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to get orders by status')));

      // act
      await notifier.getOrdersByStatus(tStatus);

      // assert
      expect(notifier.state.orders, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, 'Failed to get orders by status');
      verify(mockGetOrdersByStatusUseCase.call(const GetOrdersByStatusParams(status: tStatus)));
    });

    test('should clear error message', () async {
      // arrange - first create an error
      when(mockGetOrdersUseCase.call(NoParams()))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));
      await notifier.getOrders();

      // act
      notifier.clearError();

      // assert
      expect(notifier.state.errorMessage, isNull);
    });
  });
}
