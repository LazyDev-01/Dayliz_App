import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/user_profile_data_source.dart';
import 'package:dayliz_app/data/repositories/user_profile_repository_impl.dart';
import 'package:dayliz_app/domain/entities/address.dart';
import 'package:dayliz_app/domain/entities/user_profile.dart';
import 'package:dayliz_app/data/models/user_profile_model.dart';

@GenerateMocks([UserProfileDataSource, NetworkInfo, File])
import 'user_profile_repository_test.mocks.dart';

void main() {
  late UserProfileRepositoryImpl repository;
  late MockUserProfileDataSource mockRemoteDataSource;
  late MockUserProfileDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockFile mockFile;

  setUp(() {
    mockRemoteDataSource = MockUserProfileDataSource();
    mockLocalDataSource = MockUserProfileDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockFile = MockFile();
    repository = UserProfileRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getUserProfile', () {
    final tUserId = 'test_user_id';
    final tUserProfileModel = UserProfileModel(
      id: '1',
      userId: tUserId,
      fullName: 'Test User',
    );

    test(
      'should return remote data when the call to remote data source is successful',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.getUserProfile(any))
            .thenAnswer((_) async => tUserProfileModel);
        when(mockLocalDataSource.updateUserProfile(any))
            .thenAnswer((_) async => tUserProfileModel);

        // act
        final result = await repository.getUserProfile(tUserId);

        // assert
        verify(mockRemoteDataSource.getUserProfile(tUserId));
        verify(mockLocalDataSource.updateUserProfile(tUserProfileModel));
        expect(result, equals(Right(tUserProfileModel)));
      },
    );

    test(
      'should cache the data locally when the call to remote data source is successful',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.getUserProfile(any))
            .thenAnswer((_) async => tUserProfileModel);
        when(mockLocalDataSource.updateUserProfile(any))
            .thenAnswer((_) async => tUserProfileModel);

        // act
        await repository.getUserProfile(tUserId);

        // assert
        verify(mockRemoteDataSource.getUserProfile(tUserId));
        verify(mockLocalDataSource.updateUserProfile(tUserProfileModel));
      },
    );

    test(
      'should return server failure when the call to remote data source is unsuccessful',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.getUserProfile(any))
            .thenThrow(ServerException(message: 'Server error'));
        when(mockLocalDataSource.getUserProfile(any))
            .thenThrow(ServerException(message: 'Local error'));

        // act
        final result = await repository.getUserProfile(tUserId);

        // assert
        verify(mockRemoteDataSource.getUserProfile(tUserId));
        expect(result, equals(Left(ServerFailure(message: 'Server error'))));
      },
    );

    test(
      'should return last locally cached data when cached data is present and the device is offline',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockLocalDataSource.getUserProfile(any))
            .thenAnswer((_) async => tUserProfileModel);

        // act
        final result = await repository.getUserProfile(tUserId);

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getUserProfile(tUserId));
        expect(result, equals(Right(tUserProfileModel)));
      },
    );

    test(
      'should return CacheFailure when there is no cached data present and the device is offline',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockLocalDataSource.getUserProfile(any))
            .thenThrow(ServerException(message: 'No user profile found'));

        // act
        final result = await repository.getUserProfile(tUserId);

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getUserProfile(tUserId));
        expect(result, equals(Left(CacheFailure(message: 'No user profile found'))));
      },
    );
  });

  group('getUserAddresses', () {
    final tUserId = 'test_user_id';
    final List<Address> tAddresses = [
      Address(
        id: '1',
        userId: tUserId,
        addressLine1: 'Test Address 1',
        city: 'Test City',
        state: 'Test State',
        postalCode: '12345',
        country: 'Test Country',
        addressType: 'Home',
      ),
      Address(
        id: '2',
        userId: tUserId,
        addressLine1: 'Test Address 2',
        city: 'Test City',
        state: 'Test State',
        postalCode: '12345',
        country: 'Test Country',
        addressType: 'Work',
      ),
    ];

    test(
      'should return remote addresses when the call to remote data source is successful',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.getUserAddresses(any))
            .thenAnswer((_) async => tAddresses);
        when(mockLocalDataSource.addAddress(any, any))
            .thenAnswer((realInvocation) async => realInvocation.positionalArguments[1]);

        // act
        final result = await repository.getUserAddresses(tUserId);

        // assert
        verify(mockRemoteDataSource.getUserAddresses(tUserId));
        expect(result, equals(Right(tAddresses)));
      },
    );

    test(
      'should cache addresses locally when the call to remote data source is successful',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.getUserAddresses(any))
            .thenAnswer((_) async => tAddresses);
        when(mockLocalDataSource.addAddress(any, any))
            .thenAnswer((realInvocation) async => realInvocation.positionalArguments[1]);

        // act
        await repository.getUserAddresses(tUserId);

        // assert
        verify(mockRemoteDataSource.getUserAddresses(tUserId));
        verify(mockLocalDataSource.addAddress(tUserId, tAddresses[0]));
        verify(mockLocalDataSource.addAddress(tUserId, tAddresses[1]));
      },
    );

    test(
      'should return server failure when the call to remote data source is unsuccessful',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.getUserAddresses(any))
            .thenThrow(ServerException(message: 'Server error'));
        when(mockLocalDataSource.getUserAddresses(any))
            .thenThrow(ServerException(message: 'Local error'));

        // act
        final result = await repository.getUserAddresses(tUserId);

        // assert
        verify(mockRemoteDataSource.getUserAddresses(tUserId));
        expect(result, equals(Left(ServerFailure(message: 'Server error'))));
      },
    );

    test(
      'should return last locally cached addresses when the device is offline',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockLocalDataSource.getUserAddresses(any))
            .thenAnswer((_) async => tAddresses);

        // act
        final result = await repository.getUserAddresses(tUserId);

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getUserAddresses(tUserId));
        expect(result, equals(Right(tAddresses)));
      },
    );
  });

  group('addAddress', () {
    final tUserId = 'test_user_id';
    final tAddress = Address(
      id: '1',
      userId: tUserId,
      addressLine1: 'Test Address',
      city: 'Test City',
      state: 'Test State',
      postalCode: '12345',
      country: 'Test Country',
      addressType: 'Home',
    );

    test(
      'should add address remotely when online and cache it locally',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.addAddress(any, any))
            .thenAnswer((_) async => tAddress);
        when(mockLocalDataSource.addAddress(any, any))
            .thenAnswer((_) async => tAddress);

        // act
        final result = await repository.addAddress(tUserId, tAddress);

        // assert
        verify(mockRemoteDataSource.addAddress(tUserId, tAddress));
        verify(mockLocalDataSource.addAddress(tUserId, tAddress));
        expect(result, equals(Right(tAddress)));
      },
    );

    test(
      'should add address locally when offline',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockLocalDataSource.addAddress(any, any))
            .thenAnswer((_) async => tAddress);

        // act
        final result = await repository.addAddress(tUserId, tAddress);

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.addAddress(tUserId, tAddress));
        expect(result, equals(Right(tAddress)));
      },
    );

    test(
      'should return server failure when remote add address fails',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.addAddress(any, any))
            .thenThrow(ServerException(message: 'Server error'));

        // act
        final result = await repository.addAddress(tUserId, tAddress);

        // assert
        verify(mockRemoteDataSource.addAddress(tUserId, tAddress));
        verifyZeroInteractions(mockLocalDataSource);
        expect(result, equals(Left(ServerFailure(message: 'Server error'))));
      },
    );
  });

  group('updateProfileImage', () {
    final tUserId = 'test_user_id';
    final tImagePath = 'test_image_path';

    test(
      'should update image remotely and cache it locally when online',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.updateProfileImage(any, any))
            .thenAnswer((_) async => tImagePath);
        when(mockLocalDataSource.updateProfileImage(any, any))
            .thenAnswer((_) async => tImagePath);

        // act
        final result = await repository.updateProfileImage(tUserId, mockFile);

        // assert
        verify(mockRemoteDataSource.updateProfileImage(tUserId, mockFile));
        verify(mockLocalDataSource.updateProfileImage(tUserId, mockFile));
        expect(result, equals(Right(tImagePath)));
      },
    );

    test(
      'should return network failure when offline',
      () async {
        // arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // act
        final result = await repository.updateProfileImage(tUserId, mockFile);

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verifyZeroInteractions(mockLocalDataSource);
        expect(result, equals(Left(NetworkFailure(message: 'No internet connection'))));
      },
    );
  });

  // Additional tests for updateAddress, deleteAddress, setDefaultAddress, updateUserPreferences, etc.
  // would follow the same pattern as above
}