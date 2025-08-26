import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/auth_data_source.dart';
import 'package:dayliz_app/data/datasources/auth_local_data_source.dart';
import 'package:dayliz_app/data/models/user_model.dart';
import 'package:dayliz_app/data/repositories/auth_repository_impl.dart';
import 'package:dayliz_app/domain/entities/user.dart';

@GenerateMocks([AuthDataSource, AuthLocalDataSourceImpl, NetworkInfo])
import 'auth_repository_impl_test.mocks.dart';

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthDataSource mockRemoteDataSource;
  late MockAuthLocalDataSourceImpl mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockAuthDataSource();
    mockLocalDataSource = MockAuthLocalDataSourceImpl();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
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
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.register(
        tEmail, tPassword, tName, phone: tPhone,
      )).thenAnswer((_) async => tUserModel);

      // act
      await repository.register(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      );

      // assert
      verify(mockNetworkInfo.isConnected);
    });

    group('device is online', () {

      test('should return remote data when the call to remote data source is successful', () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.register(
          tEmail,
          tPassword,
          tName,
          phone: tPhone,
        )).thenAnswer((_) async => tUserModel);
        when(mockLocalDataSource.cacheUser(tUserModel)).thenAnswer((_) async => true);

        // act
        final result = await repository.register(
          email: tEmail,
          password: tPassword,
          name: tName,
          phone: tPhone,
        );

        // assert
        verify(mockRemoteDataSource.register(
          tEmail,
          tPassword,
          tName,
          phone: tPhone,
        ));
        expect(result, equals(const Right(tUser)));
      });

      test('should cache the data locally when the call to remote data source is successful', () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.register(
          tEmail,
          tPassword,
          tName,
          phone: tPhone,
        )).thenAnswer((_) async => tUserModel);
        when(mockLocalDataSource.cacheUser(tUserModel)).thenAnswer((_) async => true);

        // act
        await repository.register(
          email: tEmail,
          password: tPassword,
          name: tName,
          phone: tPhone,
        );

        // assert
        verify(mockRemoteDataSource.register(
          tEmail,
          tPassword,
          tName,
          phone: tPhone,
        ));
        verify(mockLocalDataSource.cacheUser(tUserModel));
      });

      test('should return server failure when the call to remote data source is unsuccessful', () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.register(
          tEmail,
          tPassword,
          tName,
          phone: tPhone,
        )).thenThrow(ServerException(message: 'Server error'));

        // act
        final result = await repository.register(
          email: tEmail,
          password: tPassword,
          name: tName,
          phone: tPhone,
        );

        // assert
        verify(mockRemoteDataSource.register(
          tEmail,
          tPassword,
          tName,
          phone: tPhone,
        ));
        verifyZeroInteractions(mockLocalDataSource);
        expect(result, equals(Left(const ServerFailure(message: 'Server error'))));
      });
    });

    group('device is offline', () {
      test('should return network failure when device is offline', () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // act
        final result = await repository.register(
          email: tEmail,
          password: tPassword,
          name: tName,
          phone: tPhone,
        );

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verifyZeroInteractions(mockLocalDataSource);
        expect(result, equals(Left(const NetworkFailure(message: 'No internet connection'))));
      });
    });
  });
}
