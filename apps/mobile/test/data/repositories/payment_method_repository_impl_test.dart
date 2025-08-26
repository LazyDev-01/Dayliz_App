import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/payment_method_local_data_source.dart';
import 'package:dayliz_app/data/datasources/payment_method_remote_data_source.dart';
import 'package:dayliz_app/data/repositories/payment_method_repository_impl.dart';
import 'package:dayliz_app/data/models/payment_method_model.dart';
import 'package:dayliz_app/domain/entities/payment_method.dart';

@GenerateMocks([
  PaymentMethodRemoteDataSource,
  PaymentMethodLocalDataSource,
  NetworkInfo,
])
import 'payment_method_repository_impl_test.mocks.dart';

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

  const tPaymentMethodModel = PaymentMethodModel(
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

  const tPaymentMethodModels = [tPaymentMethodModel];

  group('getPaymentMethods', () {
    test('should check if the device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getPaymentMethods(tUserId)).thenAnswer((_) async => tPaymentMethodModels);

      // act
      await repository.getPaymentMethods(tUserId);

      // assert
      verify(mockNetworkInfo.isConnected);
    });

    group('device is online', () {

      test('should return remote data when the call to remote data source is successful', () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.getPaymentMethods(tUserId)).thenAnswer((_) async => tPaymentMethodModels);
        when(mockLocalDataSource.cachePaymentMethods(tUserId, tPaymentMethodModels)).thenAnswer((_) async {});

        // act
        final result = await repository.getPaymentMethods(tUserId);

        // assert
        verify(mockRemoteDataSource.getPaymentMethods(tUserId));
        verify(mockLocalDataSource.cachePaymentMethods(tUserId, tPaymentMethodModels));
        expect(result, equals(const Right(tPaymentMethodModels)));
      });

      test('should return server failure when the call to remote data source is unsuccessful', () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.getPaymentMethods(tUserId))
            .thenThrow(ServerException(message: 'Server error'));

        // act
        final result = await repository.getPaymentMethods(tUserId);

        // assert
        verify(mockRemoteDataSource.getPaymentMethods(tUserId));
        expect(result, equals(const Left(ServerFailure())));
      });
    });

    group('device is offline', () {

      test('should return last locally cached data when cached data is present', () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockLocalDataSource.getPaymentMethods(tUserId)).thenAnswer((_) async => tPaymentMethodModels);

        // act
        final result = await repository.getPaymentMethods(tUserId);

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getPaymentMethods(tUserId));
        expect(result, equals(const Right(tPaymentMethodModels)));
      });

      test('should return CacheFailure when there is no cached data present', () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockLocalDataSource.getPaymentMethods(tUserId))
            .thenThrow(CacheException(message: 'No cached data'));

        // act
        final result = await repository.getPaymentMethods(tUserId);

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getPaymentMethods(tUserId));
        expect(result, equals(const Left(CacheFailure())));
      });
    });
  });

  group('getPaymentMethod', () {
    test('should return payment method when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getPaymentMethod(tPaymentMethodId)).thenAnswer((_) async => tPaymentMethodModel);
      when(mockLocalDataSource.cachePaymentMethod(tPaymentMethodModel)).thenAnswer((_) async {});

      // act
      final result = await repository.getPaymentMethod(tPaymentMethodId);

      // assert
      verify(mockRemoteDataSource.getPaymentMethod(tPaymentMethodId));
      verify(mockLocalDataSource.cachePaymentMethod(tPaymentMethodModel));
      expect(result, equals(const Right(tPaymentMethodModel)));
    });

    test('should return cached payment method when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.getPaymentMethod(tPaymentMethodId)).thenAnswer((_) async => tPaymentMethodModel);

      // act
      final result = await repository.getPaymentMethod(tPaymentMethodId);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getPaymentMethod(tPaymentMethodId));
      expect(result, equals(const Right(tPaymentMethodModel)));
    });
  });

  group('getDefaultPaymentMethod', () {
    test('should return default payment method when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getDefaultPaymentMethod(tUserId)).thenAnswer((_) async => tPaymentMethodModel);
      when(mockLocalDataSource.cachePaymentMethod(tPaymentMethodModel)).thenAnswer((_) async {});

      // act
      final result = await repository.getDefaultPaymentMethod(tUserId);

      // assert
      verify(mockRemoteDataSource.getDefaultPaymentMethod(tUserId));
      verify(mockLocalDataSource.cachePaymentMethod(tPaymentMethodModel));
      expect(result, equals(const Right(tPaymentMethodModel)));
    });

    test('should return null when no default payment method exists', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getDefaultPaymentMethod(tUserId)).thenAnswer((_) async => null);

      // act
      final result = await repository.getDefaultPaymentMethod(tUserId);

      // assert
      verify(mockRemoteDataSource.getDefaultPaymentMethod(tUserId));
      expect(result, equals(const Right(null)));
    });

    test('should return cached default payment method when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(mockLocalDataSource.getDefaultPaymentMethod(tUserId)).thenAnswer((_) async => tPaymentMethodModel);

      // act
      final result = await repository.getDefaultPaymentMethod(tUserId);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      verify(mockLocalDataSource.getDefaultPaymentMethod(tUserId));
      expect(result, equals(const Right(tPaymentMethodModel)));
    });
  });

  group('addPaymentMethod', () {
    test('should return payment method when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.addPaymentMethod(tPaymentMethodModel)).thenAnswer((_) async => tPaymentMethodModel);
      when(mockLocalDataSource.cachePaymentMethod(tPaymentMethodModel)).thenAnswer((_) async {});

      // act
      final result = await repository.addPaymentMethod(tPaymentMethod);

      // assert
      verify(mockRemoteDataSource.addPaymentMethod(tPaymentMethodModel));
      verify(mockLocalDataSource.cachePaymentMethod(tPaymentMethodModel));
      expect(result, equals(const Right(tPaymentMethodModel)));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.addPaymentMethod(tPaymentMethod);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure())));
    });

    test('should return server failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.addPaymentMethod(tPaymentMethodModel))
          .thenThrow(ServerException(message: 'Failed to add payment method'));

      // act
      final result = await repository.addPaymentMethod(tPaymentMethod);

      // assert
      verify(mockRemoteDataSource.addPaymentMethod(tPaymentMethodModel));
      expect(result, equals(const Left(ServerFailure())));
    });
  });

  group('updatePaymentMethod', () {
    test('should return updated payment method when the call to remote data source is successful', () async {
      // arrange
      final updatedPaymentMethod = tPaymentMethod.copyWith(name: 'Updated Card');
      final updatedPaymentMethodModel = PaymentMethodModel.fromEntity(updatedPaymentMethod);
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.updatePaymentMethod(updatedPaymentMethodModel)).thenAnswer((_) async => updatedPaymentMethodModel);
      when(mockLocalDataSource.cachePaymentMethod(updatedPaymentMethodModel)).thenAnswer((_) async {});

      // act
      final result = await repository.updatePaymentMethod(updatedPaymentMethod);

      // assert
      verify(mockRemoteDataSource.updatePaymentMethod(updatedPaymentMethodModel));
      verify(mockLocalDataSource.cachePaymentMethod(updatedPaymentMethodModel));
      expect(result, equals(Right(updatedPaymentMethodModel)));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.updatePaymentMethod(tPaymentMethod);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure())));
    });
  });

  group('deletePaymentMethod', () {
    test('should return true when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.deletePaymentMethod(tPaymentMethodId)).thenAnswer((_) async => true);
      when(mockLocalDataSource.removePaymentMethod(tPaymentMethodId)).thenAnswer((_) async {});

      // act
      final result = await repository.deletePaymentMethod(tPaymentMethodId);

      // assert
      verify(mockRemoteDataSource.deletePaymentMethod(tPaymentMethodId));
      verify(mockLocalDataSource.removePaymentMethod(tPaymentMethodId));
      expect(result, equals(const Right(true)));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.deletePaymentMethod(tPaymentMethodId);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure())));
    });
  });

  group('setDefaultPaymentMethod', () {
    test('should return updated payment method when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.setDefaultPaymentMethod(tPaymentMethodId, tUserId)).thenAnswer((_) async => tPaymentMethodModel);
      when(mockLocalDataSource.cachePaymentMethod(tPaymentMethodModel)).thenAnswer((_) async {});
      when(mockLocalDataSource.getPaymentMethods(tUserId)).thenAnswer((_) async => tPaymentMethodModels);
      when(mockLocalDataSource.cachePaymentMethods(tUserId, tPaymentMethodModels)).thenAnswer((_) async {});

      // act
      final result = await repository.setDefaultPaymentMethod(tPaymentMethodId, tUserId);

      // assert
      verify(mockRemoteDataSource.setDefaultPaymentMethod(tPaymentMethodId, tUserId));
      verify(mockLocalDataSource.cachePaymentMethod(tPaymentMethodModel));
      expect(result, equals(const Right(tPaymentMethodModel)));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.setDefaultPaymentMethod(tPaymentMethodId, tUserId);

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure())));
    });
  });
}
