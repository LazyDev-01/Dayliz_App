import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/data/datasources/product_local_data_source.dart';
import 'package:dayliz_app/data/datasources/product_remote_data_source.dart';
import 'package:dayliz_app/data/repositories/product_repository_impl.dart';
import 'package:dayliz_app/data/models/product_model.dart';

import 'product_repository_impl_test.mocks.dart';

// Generate mocks
@GenerateMocks([ProductRemoteDataSource, ProductLocalDataSource, NetworkInfo])

void main() {
  late ProductRepositoryImpl repository;
  late MockProductRemoteDataSource mockRemoteDataSource;
  late MockProductLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockProductRemoteDataSource();
    mockLocalDataSource = MockProductLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = ProductRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  const tProductId = 'test-product-id';
  const tCategoryId = 'test-category-id';
  const tSubcategoryId = 'test-subcategory-id';
  const tSearchQuery = 'test query';
  const tPage = 1;
  const tLimit = 10;

  const tProductModel = ProductModel(
    id: tProductId,
    name: 'Test Product',
    description: 'Test Description',
    price: 99.99,
    discountPercentage: 10.0,
    rating: 4.5,
    reviewCount: 100,
    mainImageUrl: 'https://example.com/image.jpg',
    inStock: true,
    stockQuantity: 50,
    categoryId: tCategoryId,
    subcategoryId: tSubcategoryId,
    brand: 'Test Brand',
  );

  const tProductList = [tProductModel];

  group('getProducts', () {
    test('should check if the device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getProducts(
        page: anyNamed('page'),
        limit: anyNamed('limit'),
        categoryId: anyNamed('categoryId'),
        subcategoryId: anyNamed('subcategoryId'),
        searchQuery: anyNamed('searchQuery'),
        sortBy: anyNamed('sortBy'),
        ascending: anyNamed('ascending'),
        minPrice: anyNamed('minPrice'),
        maxPrice: anyNamed('maxPrice'),
      )).thenAnswer((_) async => tProductList);

      // act
      await repository.getProducts(
        page: tPage,
        limit: tLimit,
        categoryId: tCategoryId,
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
        when(mockRemoteDataSource.getProducts(
          page: anyNamed('page'),
          limit: anyNamed('limit'),
          categoryId: anyNamed('categoryId'),
          subcategoryId: anyNamed('subcategoryId'),
          searchQuery: anyNamed('searchQuery'),
          sortBy: anyNamed('sortBy'),
          ascending: anyNamed('ascending'),
          minPrice: anyNamed('minPrice'),
          maxPrice: anyNamed('maxPrice'),
        )).thenAnswer((_) async => tProductList);

        // act
        final result = await repository.getProducts(
          page: tPage,
          limit: tLimit,
          categoryId: tCategoryId,
        );

        // assert
        verify(mockRemoteDataSource.getProducts(
          page: tPage,
          limit: tLimit,
          categoryId: tCategoryId,
          subcategoryId: null,
          searchQuery: null,
          sortBy: null,
          ascending: null,
          minPrice: null,
          maxPrice: null,
        ));
        expect(result, equals(const Right(tProductList)));
      });

      test('should cache the data locally when the call to remote data source is successful', () async {
        // arrange
        when(mockRemoteDataSource.getProducts(
          page: anyNamed('page'),
          limit: anyNamed('limit'),
          categoryId: anyNamed('categoryId'),
          subcategoryId: anyNamed('subcategoryId'),
          searchQuery: anyNamed('searchQuery'),
          sortBy: anyNamed('sortBy'),
          ascending: anyNamed('ascending'),
          minPrice: anyNamed('minPrice'),
          maxPrice: anyNamed('maxPrice'),
        )).thenAnswer((_) async => tProductList);

        // act
        await repository.getProducts(
          page: tPage,
          limit: tLimit,
          categoryId: tCategoryId,
        );

        // assert
        verify(mockRemoteDataSource.getProducts(
          page: tPage,
          limit: tLimit,
          categoryId: tCategoryId,
          subcategoryId: null,
          searchQuery: null,
          sortBy: null,
          ascending: null,
          minPrice: null,
          maxPrice: null,
        ));
        verify(mockLocalDataSource.cacheProducts(tProductList));
      });

      test('should return server failure when the call to remote data source is unsuccessful', () async {
        // arrange
        when(mockRemoteDataSource.getProducts(
          page: anyNamed('page'),
          limit: anyNamed('limit'),
          categoryId: anyNamed('categoryId'),
          subcategoryId: anyNamed('subcategoryId'),
          searchQuery: anyNamed('searchQuery'),
          sortBy: anyNamed('sortBy'),
          ascending: anyNamed('ascending'),
          minPrice: anyNamed('minPrice'),
          maxPrice: anyNamed('maxPrice'),
        )).thenThrow(ServerException(message: 'Server error'));

        // act
        final result = await repository.getProducts(
          page: tPage,
          limit: tLimit,
          categoryId: tCategoryId,
        );

        // assert
        verify(mockRemoteDataSource.getProducts(
          page: tPage,
          limit: tLimit,
          categoryId: tCategoryId,
          subcategoryId: null,
          searchQuery: null,
          sortBy: null,
          ascending: null,
          minPrice: null,
          maxPrice: null,
        ));
        expect(result, equals(const Left(ServerFailure(message: 'Server error'))));
      });
    });

    group('device is offline', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });

      test('should return last locally cached data when cached data is present', () async {
        // arrange
        when(mockLocalDataSource.getCachedProducts()).thenAnswer((_) async => tProductList);

        // act
        final result = await repository.getProducts(
          page: tPage,
          limit: tLimit,
          categoryId: tCategoryId,
        );

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getCachedProducts());
        expect(result, equals(const Right(tProductList)));
      });

      test('should return CacheFailure when there is no cached data present', () async {
        // arrange
        when(mockLocalDataSource.getCachedProducts())
            .thenThrow(CacheException(message: 'No cached data'));

        // act
        final result = await repository.getProducts(
          page: tPage,
          limit: tLimit,
          categoryId: tCategoryId,
        );

        // assert
        verifyZeroInteractions(mockRemoteDataSource);
        verify(mockLocalDataSource.getCachedProducts());
        expect(result, equals(const Left(CacheFailure(message: 'No cached data'))));
      });
    });
  });

  group('getProductById', () {
    test('should return product when the call to remote data source is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getProductById(any)).thenAnswer((_) async => tProductModel);

      // act
      final result = await repository.getProductById(tProductId);

      // assert
      verify(mockRemoteDataSource.getProductById(tProductId));
      expect(result, equals(const Right(tProductModel)));
    });

    test('should return failure when the call to remote data source is unsuccessful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getProductById(any))
          .thenThrow(ServerException(message: 'Product not found'));

      // act
      final result = await repository.getProductById(tProductId);

      // assert
      verify(mockRemoteDataSource.getProductById(tProductId));
      expect(result, equals(const Left(ServerFailure(message: 'Product not found'))));
    });
  });
}
