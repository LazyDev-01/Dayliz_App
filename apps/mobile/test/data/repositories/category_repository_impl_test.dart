import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/category_remote_data_source.dart';
import 'package:dayliz_app/data/repositories/category_repository_impl.dart';
import 'package:dayliz_app/data/models/category_model.dart';

// Generate mocks
@GenerateMocks([
  CategoryRemoteDataSource,
  NetworkInfo,
])
import 'category_repository_impl_test.mocks.dart';

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

  const tCategoryModel = CategoryModel(
    id: '1',
    name: 'Electronics',
    icon: Icons.devices,
    themeColor: Colors.blue,
    displayOrder: 1,
    subCategories: [
      SubCategoryModel(
        id: '101',
        name: 'Smartphones',
        parentId: '1',
        imageUrl: 'https://via.placeholder.com/150',
        displayOrder: 1,
        productCount: 15,
      ),
    ],
  );

  const tCategoryModels = [tCategoryModel];
  const tCategoryId = '1';

  group('getCategories', () {
    test('should return remote data when the call to remote data source is successful', () async {
      // arrange
      when(mockRemoteDataSource.getCategories()).thenAnswer((_) async => tCategoryModels);

      // act
      final result = await repository.getCategories();

      // assert
      verify(mockRemoteDataSource.getCategories());
      verifyZeroInteractions(mockNetworkInfo);
      expect(result, equals(const Right(tCategoryModels)));
    });

    test('should return server failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockRemoteDataSource.getCategories())
          .thenThrow(ServerException(message: 'Server error'));

      // act
      final result = await repository.getCategories();

      // assert
      verify(mockRemoteDataSource.getCategories());
      verifyZeroInteractions(mockNetworkInfo);
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
      final result = await repositoryWithoutRemote.getCategories();

      // assert
      verify(mockNetworkInfo.isConnected);
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
      final result = await repositoryWithoutRemote.getCategories();

      // assert
      verify(mockNetworkInfo.isConnected);
      expect(result, equals(const Left(NetworkFailure())));
    });
  });

  group('getCategoryById', () {
    test('should return category when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getCategoryById(tCategoryId)).thenAnswer((_) async => tCategoryModel);

      // act
      final result = await repository.getCategoryById(tCategoryId);

      // assert
      verify(mockRemoteDataSource.getCategoryById(tCategoryId));
      expect(result, equals(const Right(tCategoryModel)));
    });

    test('should return failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getCategoryById(tCategoryId))
          .thenThrow(ServerException(message: 'Category not found'));

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
      when(mockRemoteDataSource.getCategoriesWithSubcategories()).thenAnswer((_) async => tCategoryModels);

      // act
      final result = await repository.getCategoriesWithSubcategories();

      // assert
      verify(mockRemoteDataSource.getCategoriesWithSubcategories());
      expect(result, equals(const Right(tCategoryModels)));
    });

    test('should return server failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockRemoteDataSource.getCategoriesWithSubcategories())
          .thenThrow(ServerException(message: 'Server error'));

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
