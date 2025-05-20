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

@GenerateMocks([AuthRemoteDataSource, AuthLocalDataSource, NetworkInfo])
import 'auth_repository_impl_test.mocks.dart';

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  final tEmail = 'test@example.com';
  final tPassword = 'Password123!';
  final tName = 'Test User';
  final tPhone = '1234567890';

  final tUserModel = UserModel(
    id: 'test-id',
    email: tEmail,
    name: tName,
    phone: tPhone,
    isEmailVerified: false,
  );

  final User tUser = tUserModel;

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
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test('should return remote data when the call to remote data source is successful', () async {
        // arrange
        when(mockRemoteDataSource.register(
          email: anyNamed('email'),
          password: anyNamed('password'),
          name: anyNamed('name'),
          phone: anyNamed('phone'),
        )).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.register(
          email: tEmail,
          password: tPassword,
          name: tName,
          phone: tPhone,
        );

        // assert
        verify(mockRemoteDataSource.register(
          email: tEmail,
          password: tPassword,
          name: tName,
          phone: tPhone,
        ));
        expect(result, equals(Right(tUser)));
      });

      test('should cache the data locally when the call to remote data source is successful', () async {
        // arrange
        when(mockRemoteDataSource.register(
          email: anyNamed('email'),
          password: anyNamed('password'),
          name: anyNamed('name'),
          phone: anyNamed('phone'),
        )).thenAnswer((_) async => tUserModel);

        // act
        await repository.register(
          email: tEmail,
          password: tPassword,
          name: tName,
          phone: tPhone,
        );

        // assert
        verify(mockRemoteDataSource.register(
          email: tEmail,
          password: tPassword,
          name: tName,
          phone: tPhone,
        ));
        verify(mockLocalDataSource.cacheUser(tUserModel));
      });

      test('should return server failure when the call to remote data source is unsuccessful', () async {
        // arrange
        when(mockRemoteDataSource.register(
          email: anyNamed('email'),
          password: anyNamed('password'),
          name: anyNamed('name'),
          phone: anyNamed('phone'),
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
          email: tEmail,
          password: tPassword,
          name: tName,
          phone: tPhone,
        ));
        verifyZeroInteractions(mockLocalDataSource);
        expect(result, equals(Left(ServerFailure(message: 'Server error'))));
      });
    });

    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test('should return network failure when device is offline', () async {
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
        expect(result, equals(Left(NetworkFailure(message: 'No internet connection'))));
      });
    });
  });
}
