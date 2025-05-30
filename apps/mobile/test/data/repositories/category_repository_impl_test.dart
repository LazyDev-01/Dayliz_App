import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/error/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/category_remote_data_source.dart';
import 'package:dayliz_app/data/repositories/category_repository_impl.dart';
import 'package:dayliz_app/domain/entities/category.dart';

// Manual mock classes
class MockCategoryRemoteDataSource extends Mock implements CategoryRemoteDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late CategoryRepositoryImpl repository;
  late MockCategoryRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockCategoryRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = CategoryRepositoryImpl(
      networkInfo: mockNetworkInfo,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  const tCategory = Category(
    id: '1',
    name: 'Electronics',
    icon: Icons.devices,
    themeColor: Colors.blue,
    displayOrder: 1,
    subCategories: [
      SubCategory(
        id: '101',
        name: 'Smartphones',
        parentId: '1',
        imageUrl: 'https://via.placeholder.com/150',
        displayOrder: 1,
        productCount: 15,
      ),
    ],
  );

  const tSubCategory = SubCategory(
    id: '101',
    name: 'Smartphones',
    parentId: '1',
    imageUrl: 'https://via.placeholder.com/150',
    displayOrder: 1,
    productCount: 15,
  );

  const tCategories = [tCategory];
  const tSubCategories = [tSubCategory];
  const tCategoryId = '1';

  group('getCategories', () {
    test('should check if the device is online when remote data source is provided', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getCategories()).thenAnswer((_) async => tCategories);

      // act
      await repository.getCategories();

      // assert
      verify(mockNetworkInfo.isConnected);
    });

    group('device is online', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });

      test('should return remote data when the call to remote data source is successful', () async {
        // arrange
        when(mockRemoteDataSource.getCategories()).thenAnswer((_) async => tCategories);

        // act
        final result = await repository.getCategories();

        // assert
        verify(mockRemoteDataSource.getCategories());
        expect(result, equals(const Right(tCategories)));
      });

      test('should return server failure when the call to remote data source is unsuccessful', () async {
        // arrange
        when(mockRemoteDataSource.getCategories())
            .thenThrow(const ServerException(message: 'Server error'));

        // act
        final result = await repository.getCategories();

        // assert
        verify(mockRemoteDataSource.getCategories());
        expect(result, equals(const Left(ServerFailure(message: 'Server error'))));
      });

      test('should return mock data when no remote data source is provided', () async {
        // arrange
        final repositoryWithoutRemote = CategoryRepositoryImpl(
          networkInfo: mockNetworkInfo,
          remoteDataSource: null,
        );

        // act
        final result = await repositoryWithoutRemote.getCategories();

        // assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return categories'),
          (categories) => expect(categories.isNotEmpty, true),
        );
      });
    });

    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test('should return network failure when device is offline and no remote data source', () async {
        // arrange
        final repositoryWithoutRemote = CategoryRepositoryImpl(
          networkInfo: mockNetworkInfo,
          remoteDataSource: null,
        );

        // act
        final result = await repositoryWithoutRemote.getCategories();

        // assert
        expect(result, equals(const Left(NetworkFailure())));
      });
    });
  });

  group('getCategoryById', () {
    test('should return category when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getCategoryById(any)).thenAnswer((_) async => tCategory);

      // act
      final result = await repository.getCategoryById(tCategoryId);

      // assert
      verify(mockRemoteDataSource.getCategoryById(tCategoryId));
      expect(result, equals(const Right(tCategory)));
    });

    test('should return failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getCategoryById(any))
          .thenThrow(const ServerException(message: 'Category not found'));

      // act
      final result = await repository.getCategoryById(tCategoryId);

      // assert
      verify(mockRemoteDataSource.getCategoryById(tCategoryId));
      expect(result, equals(const Left(ServerFailure(message: 'Category not found'))));
    });

    test('should return mock category when no remote data source is provided and device is online', () async {
      // arrange
      final repositoryWithoutRemote = CategoryRepositoryImpl(
        networkInfo: mockNetworkInfo,
        remoteDataSource: null,
      );
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // act
      final result = await repositoryWithoutRemote.getCategoryById('1');

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return category'),
        (category) => expect(category.id, '1'),
      );
    });

    test('should return failure when category not found in mock data', () async {
      // arrange
      final repositoryWithoutRemote = CategoryRepositoryImpl(
        networkInfo: mockNetworkInfo,
        remoteDataSource: null,
      );
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // act
      final result = await repositoryWithoutRemote.getCategoryById('999');

      // assert
      expect(result, equals(const Left(ServerFailure(message: 'Category not found'))));
    });

    test('should return network failure when device is offline', () async {
      // arrange
      final repositoryWithoutRemote = CategoryRepositoryImpl(
        networkInfo: mockNetworkInfo,
        remoteDataSource: null,
      );
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repositoryWithoutRemote.getCategoryById(tCategoryId);

      // assert
      expect(result, equals(const Left(NetworkFailure())));
    });
  });

  group('getSubcategories', () {
    test('should return subcategories when device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // act
      final result = await repository.getSubcategories(tCategoryId);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return subcategories'),
        (subcategories) => expect(subcategories.isNotEmpty, true),
      );
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.getSubcategories(tCategoryId);

      // assert
      expect(result, equals(const Left(NetworkFailure())));
    });

    test('should return server failure when category not found', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // act
      final result = await repository.getSubcategories('999');

      // assert
      expect(result, equals(const Left(ServerFailure())));
    });
  });

  group('getCategoriesWithSubcategories', () {
    test('should return remote data when the call to remote data source is successful', () async {
      // arrange
      when(mockRemoteDataSource.getCategoriesWithSubcategories()).thenAnswer((_) async => tCategories);

      // act
      final result = await repository.getCategoriesWithSubcategories();

      // assert
      verify(mockRemoteDataSource.getCategoriesWithSubcategories());
      expect(result, equals(const Right(tCategories)));
    });

    test('should return server failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockRemoteDataSource.getCategoriesWithSubcategories())
          .thenThrow(const ServerException(message: 'Server error'));

      // act
      final result = await repository.getCategoriesWithSubcategories();

      // assert
      verify(mockRemoteDataSource.getCategoriesWithSubcategories());
      expect(result, equals(const Left(ServerFailure(message: 'Server error'))));
    });

    test('should return mock data when no remote data source is provided and device is online', () async {
      // arrange
      final repositoryWithoutRemote = CategoryRepositoryImpl(
        networkInfo: mockNetworkInfo,
        remoteDataSource: null,
      );
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // act
      final result = await repositoryWithoutRemote.getCategoriesWithSubcategories();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return categories'),
        (categories) => expect(categories.isNotEmpty, true),
      );
    });

    test('should return network failure when device is offline and no remote data source', () async {
      // arrange
      final repositoryWithoutRemote = CategoryRepositoryImpl(
        networkInfo: mockNetworkInfo,
        remoteDataSource: null,
      );
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repositoryWithoutRemote.getCategoriesWithSubcategories();

      // assert
      expect(result, equals(const Left(NetworkFailure())));
    });
  });
}
