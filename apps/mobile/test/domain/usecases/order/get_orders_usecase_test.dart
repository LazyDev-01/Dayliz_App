import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/usecases/usecase.dart';
import 'package:dayliz_app/domain/entities/order.dart' as domain;
import 'package:dayliz_app/domain/entities/address.dart';
import 'package:dayliz_app/domain/entities/order_item.dart';
import 'package:dayliz_app/domain/entities/payment_method.dart';
import 'package:dayliz_app/domain/repositories/order_repository.dart';
import 'package:dayliz_app/domain/usecases/orders/get_orders_usecase.dart';

// Manual mock class
class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late GetOrdersUseCase usecase;
  late MockOrderRepository mockOrderRepository;

  setUp(() {
    mockOrderRepository = MockOrderRepository();
    usecase = GetOrdersUseCase(mockOrderRepository);
  });

  const tUserId = 'test-user-id';

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
    unitPrice: 99.99,
    totalPrice: 199.98,
    imageUrl: 'https://example.com/image.jpg',
  );

  final tOrder = domain.Order(
    id: 'test-order-id',
    userId: tUserId,
    orderNumber: 'DLZ-20250609-0001',
    items: [tOrderItem],
    subtotal: 199.98,
    tax: 20.00,
    shipping: 10.00,
    total: 229.98,
    status: 'pending',
    createdAt: DateTime.now(),
    shippingAddress: tAddress,
    paymentMethod: tPaymentMethod,
  );

  final tOrders = [tOrder];

  test('should get orders from the repository', () async {
    // arrange
    when(mockOrderRepository.getOrders())
        .thenAnswer((_) async => Right(tOrders));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Right(tOrders));
    verify(mockOrderRepository.getOrders());
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockOrderRepository.getOrders())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(mockOrderRepository.getOrders());
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should return empty list when no orders found', () async {
    // arrange
    when(mockOrderRepository.getOrders())
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Right([]));
    verify(mockOrderRepository.getOrders());
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should return network failure when device is offline', () async {
    // arrange
    when(mockOrderRepository.getOrders())
        .thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(NetworkFailure(message: 'No internet connection')));
    verify(mockOrderRepository.getOrders());
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should return cache failure when no cached data available', () async {
    // arrange
    when(mockOrderRepository.getOrders())
        .thenAnswer((_) async => const Left(CacheFailure(message: 'No cached order data')));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(CacheFailure(message: 'No cached order data')));
    verify(mockOrderRepository.getOrders());
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should handle orders with different statuses', () async {
    // arrange
    final tOrderProcessing = tOrder.copyWith(status: 'processing');
    final tOrderOutForDelivery = tOrder.copyWith(status: 'out_for_delivery', id: 'order-2');
    final tOrderDelivered = tOrder.copyWith(status: 'delivered', id: 'order-3');
    final tMixedOrders = [tOrderProcessing, tOrderOutForDelivery, tOrderDelivered];

    when(mockOrderRepository.getOrders())
        .thenAnswer((_) async => Right(tMixedOrders));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Right(tMixedOrders));
    result.fold(
      (failure) => fail('Should return orders'),
      (orders) {
        expect(orders.length, 3);
        expect(orders[0].status, 'processing');
        expect(orders[1].status, 'out_for_delivery');
        expect(orders[2].status, 'delivered');
      },
    );
    verify(mockOrderRepository.getOrders());
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should handle orders with complex order items', () async {
    // arrange
    final tComplexOrderItem1 = OrderItem(
      id: 'item-1',
      productId: 'product-1',
      productName: 'Complex Product 1',
      quantity: 3,
      unitPrice: 149.99,
      totalPrice: 449.97,
      imageUrl: 'https://example.com/image1.jpg',
    );

    final tComplexOrderItem2 = OrderItem(
      id: 'item-2',
      productId: 'product-2',
      productName: 'Complex Product 2',
      quantity: 1,
      unitPrice: 299.99,
      totalPrice: 299.99,
      imageUrl: 'https://example.com/image2.jpg',
    );

    final tComplexOrder = tOrder.copyWith(
      items: [tComplexOrderItem1, tComplexOrderItem2],
      subtotal: 749.96,
      total: 824.96,
    );

    when(mockOrderRepository.getOrders())
        .thenAnswer((_) async => Right([tComplexOrder]));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Right([tComplexOrder]));
    result.fold(
      (failure) => fail('Should return orders'),
      (orders) {
        expect(orders.length, 1);
        expect(orders[0].items.length, 2);
        expect(orders[0].subtotal, 749.96);
        expect(orders[0].total, 824.96);
      },
    );
    verify(mockOrderRepository.getOrders());
    verifyNoMoreInteractions(mockOrderRepository);
  });
}
