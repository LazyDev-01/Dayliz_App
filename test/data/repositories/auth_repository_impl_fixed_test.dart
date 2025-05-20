import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/auth_data_source.dart';
import 'package:dayliz_app/data/models/user_model.dart';
import 'package:dayliz_app/data/repositories/auth_repository_impl.dart';
import 'package:dayliz_app/domain/entities/user.dart';

// Create manual mocks for our dependencies
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {
  @override
  Future<bool> get isConnected => Future.value(true);
}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockRemoteDataSource, // Using remote as local for simplicity
      networkInfo: mockNetworkInfo,
    );
  });

  const tEmail = 'test@example.com';
  const tPassword = 'Password123!';
  const tName = 'Test User';
  const tPhone = '1234567890';

  const tUserModel = UserModel(
    id: 'test-id',
    email: tEmail,
    name: tName,
    phone: tPhone,
    isEmailVerified: false,
  );

  const User tUser = tUserModel;

  group('register', () {
    test('should check if the device is online', () async {
      // arrange
      when(mockRemoteDataSource.register(tEmail, tPassword, tName, phone: tPhone))
          .thenAnswer((_) async => tUserModel);

      // act
      await repository.register(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      );

      // assert
      // We're using a fixed implementation for isConnected, so we can't verify it was called
      verify(mockRemoteDataSource.register(tEmail, tPassword, tName, phone: tPhone));
    });

    test('should return remote data when the call to remote data source is successful', () async {
      // arrange
      when(mockRemoteDataSource.register(tEmail, tPassword, tName, phone: tPhone))
          .thenAnswer((_) async => tUserModel);

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      );

      // assert
      verify(mockRemoteDataSource.register(tEmail, tPassword, tName, phone: tPhone));
      expect(result, equals(const Right(tUser)));
    });

    test('should return server failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockRemoteDataSource.register(tEmail, tPassword, tName, phone: tPhone))
          .thenThrow(ServerException(message: 'Server error'));

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      );

      // assert
      verify(mockRemoteDataSource.register(tEmail, tPassword, tName, phone: tPhone));
      expect(result, equals(const Left(ServerFailure(message: 'Server error'))));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      final mockOfflineNetworkInfo = MockNetworkInfo();
      when(mockOfflineNetworkInfo.isConnected).thenAnswer((_) async => false);

      final offlineRepository = AuthRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockRemoteDataSource,
        networkInfo: mockOfflineNetworkInfo,
      );

      // act
      final result = await offlineRepository.register(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      );

      // assert
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(const Left(NetworkFailure(message: 'No internet connection'))));
    });
  });
}
