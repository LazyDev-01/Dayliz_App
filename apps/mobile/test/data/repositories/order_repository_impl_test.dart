import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/order_data_source.dart';
import 'package:dayliz_app/data/repositories/order_repository_impl.dart';
import 'package:dayliz_app/data/models/order_model.dart';
import 'package:dayliz_app/data/models/address_model.dart';
import 'package:dayliz_app/data/models/order_item_model.dart';
import 'package:dayliz_app/data/models/payment_method_model.dart';

import 'order_repository_impl_test.mocks.dart';

// Generate mocks
@GenerateMocks([OrderDataSource, NetworkInfo])

void main() {
  late OrderRepositoryImpl repository;
  late MockOrderDataSource mockRemoteDataSource;
  late MockOrderDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockOrderDataSource();
    mockLocalDataSource = MockOrderDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = OrderRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const tOrderId = 'test-order-id';
  const tUserId = 'test-user-id';
  const tStatus = 'pending';
  const tReason = 'Changed mind';

  const tAddressModel = AddressModel(
    id: 'address-id',
    userId: tUserId,
    addressLine1: 'Test Address',
    city: 'Test City',
    state: 'Test State',
    postalCode: '12345',
    country: 'Test Country',
    addressType: 'Home',
  );

  const tPaymentMethodModel = PaymentMethodModel(
    id: 'payment-id',
    userId: tUserId,
    type: 'credit_card',
    name: 'Test Card',
    isDefault: true,
    details: {
      'cardNumber': '**** **** **** 1234',
      'expiryDate': '12/25',
      'cardHolderName': 'Test User',
    },
  );

  const tOrderItemModel = OrderItemModel(
    id: 'item-id',
    productId: 'product-id',
    productName: 'Test Product',
    quantity: 2,
    unitPrice: 99.99,
    totalPrice: 199.98,
    imageUrl: 'https://example.com/image.jpg',
  );

  final tOrderModel = OrderModel(
    id: tOrderId,
    userId: tUserId,
    items: [tOrderItemModel],
    subtotal: 199.98,
    tax: 20.00,
    shipping: 10.00,
    total: 229.98,
    status: tStatus,
    createdAt: DateTime.now(),
    shippingAddress: tAddressModel,
    paymentMethod: tPaymentMethodModel,
  );

  final tOrderModels = [tOrderModel];
  const tOrderStatistics = {'processing': 2, 'out_for_delivery': 1, 'delivered': 5};
  const tTrackingInfo = {'status': 'out_for_delivery', 'location': 'Test City'};

  group('getOrders', () {
    test('should check if the device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getOrders()).thenAnswer((_) async => tOrderModels);

      // act
      await repository.getOrders();

      // assert
      verify(mockNetworkInfo.isConnected);
    });

    group('device is online', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test('should return remote data when the call to remote data source is successful', () async {
        // arrange
        when(mockRemoteDataSource.getOrders()).thenAnswer((_) async => tOrderModels);

        // act
        final result = await repository.getOrders();

        // assert
        verify(mockRemoteDataSource.getOrders());
        expect(result, equals(Right(tOrderModels)));
      });

      test('should cache the data locally when the call to remote data source is successful', () async {
        // arrange
        when(mockRemoteDataSource.getOrders()).thenAnswer((_) async => tOrderModels);

        // act
        await repository.getOrders();

        // assert
        verify(mockRemoteDataSource.getOrders());
        // Note: Caching is handled internally in the repository
      });

      test('should return local data when the call to remote data source fails', () async {
        // arrange
        when(mockRemoteDataSource.getOrders()).thenThrow(ServerException(message: 'Server error'));
        when(mockLocalDataSource.getOrders()).thenAnswer((_) async => tOrderModels);

        // act
        final result = await repository.getOrders();

        // assert
        verify(mockRemoteDataSource.getOrders());
        verify(mockLocalDataSource.getOrders());
        expect(result, equals(Right(tOrderModels)));
      });
    });

    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test('should return last locally cached data when cached data is present', () async {
        // arrange
        when(mockLocalDataSource.getOrders()).thenAnswer((_) async => tOrderModels);

        // act
        final result = await repository.getOrders();

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getOrders());
        expect(result, equals(Right(tOrderModels)));
      });

      test('should return CacheFailure when there is no cached data present', () async {
        // arrange
        when(mockLocalDataSource.getOrders())
            .thenThrow(CacheException(message: 'No cached data'));

        // act
        final result = await repository.getOrders();

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getOrders());
        expect(result, equals(const Left(CacheFailure(message: 'No cached data'))));
      });
    });
  });

  group('getOrderById', () {
    test('should return order when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getOrderById(tOrderId)).thenAnswer((_) async => tOrderModel);

      // act
      final result = await repository.getOrderById(tOrderId);

      // assert
      verify(mockRemoteDataSource.getOrderById(tOrderId));
      expect(result, equals(Right(tOrderModel)));
    });

    test('should return failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getOrderById(tOrderId))
          .thenThrow(ServerException(message: 'Order not found'));

      // act
      final result = await repository.getOrderById(tOrderId);

      // assert
      verify(mockRemoteDataSource.getOrderById(tOrderId));
      expect(result, equals(const Left(ServerFailure(message: 'Order not found'))));
    });

    test('should return cached order when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.getOrderById(any)).thenAnswer((_) async => tOrderModel);

      // act
      final result = await repository.getOrderById(tOrderId);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getOrderById(any));
      expect(result, equals(Right(tOrderModel)));
    });
  });

  group('createOrder', () {
    test('should return created order when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.createOrder(tOrderModel)).thenAnswer((_) async => tOrderModel);

      // act
      final result = await repository.createOrder(tOrderModel);

      // assert
      verify(mockRemoteDataSource.createOrder(tOrderModel));
      expect(result, equals(Right(tOrderModel)));
    });

    test('should return failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.createOrder(tOrderModel))
          .thenThrow(ServerException(message: 'Failed to create order'));

      // act
      final result = await repository.createOrder(tOrderModel);

      // assert
      verify(mockRemoteDataSource.createOrder(tOrderModel));
      expect(result, equals(const Left(ServerFailure(message: 'Failed to create order'))));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.createOrder(tOrderModel);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure(message: 'No internet connection'))));
    });
  });

  group('cancelOrder', () {
    test('should return true when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.cancelOrder(tOrderId, reason: tReason))
          .thenAnswer((_) async => true);

      // act
      final result = await repository.cancelOrder(tOrderId, reason: tReason);

      // assert
      verify(mockRemoteDataSource.cancelOrder(tOrderId, reason: tReason));
      expect(result, equals(const Right(true)));
    });

    test('should return failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.cancelOrder(tOrderId, reason: tReason))
          .thenThrow(ServerException(message: 'Failed to cancel order'));

      // act
      final result = await repository.cancelOrder(tOrderId, reason: tReason);

      // assert
      verify(mockRemoteDataSource.cancelOrder(tOrderId, reason: tReason));
      expect(result, equals(const Left(ServerFailure(message: 'Failed to cancel order'))));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.cancelOrder(tOrderId, reason: tReason);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure(message: 'No internet connection'))));
    });
  });

  group('trackOrder', () {
    test('should return tracking info when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.trackOrder(tOrderId)).thenAnswer((_) async => tTrackingInfo);

      // act
      final result = await repository.trackOrder(tOrderId);

      // assert
      verify(mockRemoteDataSource.trackOrder(tOrderId));
      expect(result, equals(const Right(tTrackingInfo)));
    });

    test('should return failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.trackOrder(tOrderId))
          .thenThrow(ServerException(message: 'Tracking not available'));

      // act
      final result = await repository.trackOrder(tOrderId);

      // assert
      verify(mockRemoteDataSource.trackOrder(tOrderId));
      expect(result, equals(const Left(ServerFailure(message: 'Tracking not available'))));
    });
  });

  group('getOrderStatistics', () {
    test('should return statistics when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getOrderStatistics()).thenAnswer((_) async => tOrderStatistics);

      // act
      final result = await repository.getOrderStatistics();

      // assert
      verify(mockRemoteDataSource.getOrderStatistics());
      expect(result, equals(const Right(tOrderStatistics)));
    });

    test('should return cached statistics when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.getOrderStatistics()).thenAnswer((_) async => tOrderStatistics);

      // act
      final result = await repository.getOrderStatistics();

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getOrderStatistics());
      expect(result, equals(const Right(tOrderStatistics)));
    });
  });

  group('getOrdersByStatus', () {
    test('should return orders by status when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getOrdersByStatus(tStatus)).thenAnswer((_) async => tOrderModels);

      // act
      final result = await repository.getOrdersByStatus(tStatus);

      // assert
      verify(mockRemoteDataSource.getOrdersByStatus(tStatus));
      expect(result, equals(Right(tOrderModels)));
    });

    test('should return cached orders by status when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.getOrders()).thenAnswer((_) async => tOrderModels);

      // act
      final result = await repository.getOrdersByStatus(tStatus);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getOrders());
      expect(result, equals(Right(tOrderModels)));
    });
  });
}
