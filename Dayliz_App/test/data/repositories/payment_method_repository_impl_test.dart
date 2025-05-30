import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/payment_method_local_data_source.dart';
import 'package:dayliz_app/data/datasources/payment_method_remote_data_source.dart';
import 'package:dayliz_app/data/repositories/payment_method_repository_impl.dart';
import 'package:dayliz_app/domain/entities/payment_method.dart';

// Manual mock classes
class MockPaymentMethodRemoteDataSource extends Mock implements PaymentMethodRemoteDataSource {}
class MockPaymentMethodLocalDataSource extends Mock implements PaymentMethodLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late PaymentMethodRepositoryImpl repository;
  late MockPaymentMethodRemoteDataSource mockRemoteDataSource;
  late MockPaymentMethodLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockPaymentMethodRemoteDataSource();
    mockLocalDataSource = MockPaymentMethodLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = PaymentMethodRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const tUserId = 'test-user-id';
  const tPaymentMethodId = 'test-payment-method-id';

  const tPaymentMethod = PaymentMethod(
    id: tPaymentMethodId,
    userId: tUserId,
    type: PaymentMethod.typeCreditCard,
    name: 'Personal Visa',
    isDefault: true,
    details: {
      'cardNumber': '4242',
      'cardHolderName': 'John Doe',
      'expiryDate': '12/25',
      'cardType': 'visa',
      'last4': '4242',
      'brand': 'visa',
    },
  );

  const tPaymentMethods = [tPaymentMethod];

  group('getPaymentMethods', () {
    test('should check if the device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getPaymentMethods(any)).thenAnswer((_) async => tPaymentMethods);

      // act
      await repository.getPaymentMethods(tUserId);

      // assert
      verify(mockNetworkInfo.isConnected);
    });

    group('device is online', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test('should return remote data when the call to remote data source is successful', () async {
        // arrange
        when(mockRemoteDataSource.getPaymentMethods(any)).thenAnswer((_) async => tPaymentMethods);
        when(mockLocalDataSource.cachePaymentMethods(any, any)).thenAnswer((_) async => {});

        // act
        final result = await repository.getPaymentMethods(tUserId);

        // assert
        verify(mockRemoteDataSource.getPaymentMethods(tUserId));
        verify(mockLocalDataSource.cachePaymentMethods(tUserId, tPaymentMethods));
        expect(result, equals(const Right(tPaymentMethods)));
      });

      test('should return server failure when the call to remote data source is unsuccessful', () async {
        // arrange
        when(mockRemoteDataSource.getPaymentMethods(any))
            .thenThrow(const ServerException(message: 'Server error'));

        // act
        final result = await repository.getPaymentMethods(tUserId);

        // assert
        verify(mockRemoteDataSource.getPaymentMethods(tUserId));
        expect(result, equals(const Left(ServerFailure(message: 'Server error'))));
      });
    });

    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test('should return last locally cached data when cached data is present', () async {
        // arrange
        when(mockLocalDataSource.getPaymentMethods(any)).thenAnswer((_) async => tPaymentMethods);

        // act
        final result = await repository.getPaymentMethods(tUserId);

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getPaymentMethods(tUserId));
        expect(result, equals(const Right(tPaymentMethods)));
      });

      test('should return CacheFailure when there is no cached data present', () async {
        // arrange
        when(mockLocalDataSource.getPaymentMethods(any))
            .thenThrow(const CacheException(message: 'No cached data'));

        // act
        final result = await repository.getPaymentMethods(tUserId);

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getPaymentMethods(tUserId));
        expect(result, equals(const Left(CacheFailure(message: 'No cached data'))));
      });
    });
  });

  group('getPaymentMethod', () {
    test('should return payment method when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getPaymentMethod(any)).thenAnswer((_) async => tPaymentMethod);
      when(mockLocalDataSource.cachePaymentMethod(any)).thenAnswer((_) async => {});

      // act
      final result = await repository.getPaymentMethod(tPaymentMethodId);

      // assert
      verify(mockRemoteDataSource.getPaymentMethod(tPaymentMethodId));
      verify(mockLocalDataSource.cachePaymentMethod(tPaymentMethod));
      expect(result, equals(const Right(tPaymentMethod)));
    });

    test('should return cached payment method when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.getPaymentMethod(any)).thenAnswer((_) async => tPaymentMethod);

      // act
      final result = await repository.getPaymentMethod(tPaymentMethodId);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getPaymentMethod(tPaymentMethodId));
      expect(result, equals(const Right(tPaymentMethod)));
    });
  });

  group('getDefaultPaymentMethod', () {
    test('should return default payment method when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getDefaultPaymentMethod(any)).thenAnswer((_) async => tPaymentMethod);
      when(mockLocalDataSource.cachePaymentMethod(any)).thenAnswer((_) async => {});

      // act
      final result = await repository.getDefaultPaymentMethod(tUserId);

      // assert
      verify(mockRemoteDataSource.getDefaultPaymentMethod(tUserId));
      verify(mockLocalDataSource.cachePaymentMethod(tPaymentMethod));
      expect(result, equals(const Right(tPaymentMethod)));
    });

    test('should return null when no default payment method exists', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getDefaultPaymentMethod(any)).thenAnswer((_) async => null);

      // act
      final result = await repository.getDefaultPaymentMethod(tUserId);

      // assert
      verify(mockRemoteDataSource.getDefaultPaymentMethod(tUserId));
      expect(result, equals(const Right(null)));
    });

    test('should return cached default payment method when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.getDefaultPaymentMethod(any)).thenAnswer((_) async => tPaymentMethod);

      // act
      final result = await repository.getDefaultPaymentMethod(tUserId);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getDefaultPaymentMethod(tUserId));
      expect(result, equals(const Right(tPaymentMethod)));
    });
  });

  group('addPaymentMethod', () {
    test('should return payment method when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.addPaymentMethod(any)).thenAnswer((_) async => tPaymentMethod);
      when(mockLocalDataSource.cachePaymentMethod(any)).thenAnswer((_) async => {});

      // act
      final result = await repository.addPaymentMethod(tPaymentMethod);

      // assert
      verify(mockRemoteDataSource.addPaymentMethod(any));
      verify(mockLocalDataSource.cachePaymentMethod(tPaymentMethod));
      expect(result, equals(const Right(tPaymentMethod)));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.addPaymentMethod(tPaymentMethod);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure(message: 'No internet connection'))));
    });

    test('should return server failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.addPaymentMethod(any))
          .thenThrow(const ServerException(message: 'Failed to add payment method'));

      // act
      final result = await repository.addPaymentMethod(tPaymentMethod);

      // assert
      verify(mockRemoteDataSource.addPaymentMethod(any));
      expect(result, equals(const Left(ServerFailure(message: 'Failed to add payment method'))));
    });
  });

  group('updatePaymentMethod', () {
    test('should return updated payment method when the call to remote data source is successful', () async {
      // arrange
      final updatedPaymentMethod = tPaymentMethod.copyWith(name: 'Updated Card');
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.updatePaymentMethod(any)).thenAnswer((_) async => updatedPaymentMethod);
      when(mockLocalDataSource.cachePaymentMethod(any)).thenAnswer((_) async => {});

      // act
      final result = await repository.updatePaymentMethod(updatedPaymentMethod);

      // assert
      verify(mockRemoteDataSource.updatePaymentMethod(any));
      verify(mockLocalDataSource.cachePaymentMethod(updatedPaymentMethod));
      expect(result, equals(Right(updatedPaymentMethod)));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.updatePaymentMethod(tPaymentMethod);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure(message: 'No internet connection'))));
    });
  });

  group('deletePaymentMethod', () {
    test('should return true when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.deletePaymentMethod(any)).thenAnswer((_) async => true);
      when(mockLocalDataSource.deletePaymentMethod(any)).thenAnswer((_) async => {});

      // act
      final result = await repository.deletePaymentMethod(tPaymentMethodId);

      // assert
      verify(mockRemoteDataSource.deletePaymentMethod(tPaymentMethodId));
      verify(mockLocalDataSource.deletePaymentMethod(tPaymentMethodId));
      expect(result, equals(const Right(true)));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.deletePaymentMethod(tPaymentMethodId);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure(message: 'No internet connection'))));
    });
  });

  group('setDefaultPaymentMethod', () {
    test('should return updated payment method when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.setDefaultPaymentMethod(any, any)).thenAnswer((_) async => tPaymentMethod);
      when(mockLocalDataSource.cachePaymentMethod(any)).thenAnswer((_) async => {});
      when(mockLocalDataSource.getPaymentMethods(any)).thenAnswer((_) async => tPaymentMethods);
      when(mockLocalDataSource.cachePaymentMethods(any, any)).thenAnswer((_) async => {});

      // act
      final result = await repository.setDefaultPaymentMethod(tPaymentMethodId, tUserId);

      // assert
      verify(mockRemoteDataSource.setDefaultPaymentMethod(tPaymentMethodId, tUserId));
      verify(mockLocalDataSource.cachePaymentMethod(tPaymentMethod));
      expect(result, equals(const Right(tPaymentMethod)));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.setDefaultPaymentMethod(tPaymentMethodId, tUserId);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure(message: 'No internet connection'))));
    });
  });
}
