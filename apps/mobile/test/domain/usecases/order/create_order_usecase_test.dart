import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/order.dart' as domain;
import 'package:dayliz_app/domain/entities/address.dart';
import 'package:dayliz_app/domain/entities/order_item.dart';
import 'package:dayliz_app/domain/entities/payment_method.dart';
import 'package:dayliz_app/domain/repositories/order_repository.dart';
import 'package:dayliz_app/domain/usecases/orders/create_order_usecase.dart';

// Manual mock class
class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late CreateOrderUseCase usecase;
  late MockOrderRepository mockOrderRepository;

  setUp(() {
    mockOrderRepository = MockOrderRepository();
    usecase = CreateOrderUseCase(mockOrderRepository);
  });

  const tUserId = 'test-user-id';
  const tOrderId = 'test-order-id';

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
    id: tOrderId,
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

  test('should create order from the repository', () async {
    // arrange
    when(mockOrderRepository.createOrder(any))
        .thenAnswer((_) async => Right(tOrder));

    // act
    final result = await usecase(CreateOrderParams(order: tOrder));

    // assert
    expect(result, Right(tOrder));
    verify(mockOrderRepository.createOrder(tOrder));
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockOrderRepository.createOrder(any))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to create order')));

    // act
    final result = await usecase(CreateOrderParams(order: tOrder));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to create order')));
    verify(mockOrderRepository.createOrder(tOrder));
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should return network failure when device is offline', () async {
    // arrange
    when(mockOrderRepository.createOrder(any))
        .thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

    // act
    final result = await usecase(CreateOrderParams(order: tOrder));

    // assert
    expect(result, const Left(NetworkFailure(message: 'No internet connection')));
    verify(mockOrderRepository.createOrder(tOrder));
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should handle order with multiple items', () async {
    // arrange
    final tOrderItem2 = OrderItem(
      id: 'item-id-2',
      productId: 'product-id-2',
      productName: 'Test Product 2',
      quantity: 1,
      unitPrice: 149.99,
      totalPrice: 149.99,
      imageUrl: 'https://example.com/image2.jpg',
    );

    final tMultiItemOrder = tOrder.copyWith(
      items: [tOrderItem, tOrderItem2],
      subtotal: 349.97,
      total: 384.97,
    );

    when(mockOrderRepository.createOrder(any))
        .thenAnswer((_) async => Right(tMultiItemOrder));

    // act
    final result = await usecase(CreateOrderParams(order: tMultiItemOrder));

    // assert
    expect(result, Right(tMultiItemOrder));
    result.fold(
      (failure) => fail('Should return order'),
      (order) {
        expect(order.items.length, 2);
        expect(order.subtotal, 349.97);
        expect(order.total, 384.97);
      },
    );
    verify(mockOrderRepository.createOrder(tMultiItemOrder));
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should handle order with discount', () async {
    // arrange
    final tDiscountedOrder = tOrder.copyWith(
      couponCode: 'SAVE10',
      discount: 20.00,
      total: 209.98, // Original total minus discount
    );

    when(mockOrderRepository.createOrder(any))
        .thenAnswer((_) async => Right(tDiscountedOrder));

    // act
    final result = await usecase(CreateOrderParams(order: tDiscountedOrder));

    // assert
    expect(result, Right(tDiscountedOrder));
    result.fold(
      (failure) => fail('Should return order'),
      (order) {
        expect(order.couponCode, 'SAVE10');
        expect(order.discount, 20.00);
        expect(order.total, 209.98);
      },
    );
    verify(mockOrderRepository.createOrder(tDiscountedOrder));
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should handle order with different payment methods', () async {
    // arrange
    const tCashPaymentMethod = PaymentMethod(
      id: 'cash-payment-id',
      userId: 'test-user-id',
      type: 'cash_on_delivery',
      name: 'Cash on Delivery',
      isDefault: false,
      details: {},
    );

    final tCashOrder = tOrder.copyWith(paymentMethod: tCashPaymentMethod);

    when(mockOrderRepository.createOrder(any))
        .thenAnswer((_) async => Right(tCashOrder));

    // act
    final result = await usecase(CreateOrderParams(order: tCashOrder));

    // assert
    expect(result, Right(tCashOrder));
    result.fold(
      (failure) => fail('Should return order'),
      (order) {
        expect(order.paymentMethod.type, 'cash_on_delivery');
        expect(order.paymentMethod.cardNumber, isNull);
      },
    );
    verify(mockOrderRepository.createOrder(tCashOrder));
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should handle order with billing address different from shipping', () async {
    // arrange
    final tBillingAddress = Address(
      id: 'billing-address-id',
      userId: tUserId,
      addressLine1: 'Billing Address',
      city: 'Billing City',
      state: 'Billing State',
      postalCode: '54321',
      country: 'Test Country',
      addressType: 'Billing',
    );

    final tOrderWithBilling = tOrder.copyWith(billingAddress: tBillingAddress);

    when(mockOrderRepository.createOrder(any))
        .thenAnswer((_) async => Right(tOrderWithBilling));

    // act
    final result = await usecase(CreateOrderParams(order: tOrderWithBilling));

    // assert
    expect(result, Right(tOrderWithBilling));
    result.fold(
      (failure) => fail('Should return order'),
      (order) {
        expect(order.billingAddress, isNotNull);
        expect(order.billingAddress!.city, 'Billing City');
        expect(order.shippingAddress.city, 'Test City');
      },
    );
    verify(mockOrderRepository.createOrder(tOrderWithBilling));
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should return validation failure for invalid order data', () async {
    // arrange
    when(mockOrderRepository.createOrder(any))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Invalid order data')));

    // act
    final result = await usecase(CreateOrderParams(order: tOrder));

    // assert
    expect(result, const Left(ServerFailure(message: 'Invalid order data')));
    verify(mockOrderRepository.createOrder(tOrder));
    verifyNoMoreInteractions(mockOrderRepository);
  });

  test('should handle order with notes', () async {
    // arrange
    final tOrderWithNotes = tOrder.copyWith(notes: 'Please deliver after 6 PM');

    when(mockOrderRepository.createOrder(any))
        .thenAnswer((_) async => Right(tOrderWithNotes));

    // act
    final result = await usecase(CreateOrderParams(order: tOrderWithNotes));

    // assert
    expect(result, Right(tOrderWithNotes));
    result.fold(
      (failure) => fail('Should return order'),
      (order) {
        expect(order.notes, 'Please deliver after 6 PM');
      },
    );
    verify(mockOrderRepository.createOrder(tOrderWithNotes));
    verifyNoMoreInteractions(mockOrderRepository);
  });
}
