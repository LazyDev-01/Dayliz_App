import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/domain/repositories/product_repository.dart';
import 'package:dayliz_app/domain/usecases/search_products_usecase.dart';

// Manual mock class
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late SearchProductsUseCase usecase;
  late MockProductRepository mockProductRepository;

  setUp(() {
    mockProductRepository = MockProductRepository();
    usecase = SearchProductsUseCase(mockProductRepository);
  });

  const tQuery = 'apple';
  const tPage = 1;
  const tLimit = 20;

  const tProduct = Product(
    id: 'test-product-id',
    name: 'Apple iPhone',
    description: 'Latest Apple iPhone with advanced features',
    price: 999.99,
    discountPercentage: 10.0,
    rating: 4.5,
    reviewCount: 100,
    mainImageUrl: 'https://example.com/image.jpg',
    inStock: true,
    stockQuantity: 50,
    categoryId: 'electronics',
    brand: 'Apple',
  );

  const tProducts = [tProduct];

  test('should search products from the repository', () async {
    // arrange
    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Right(tProducts));

    // act
    final result = await usecase(const SearchProductsParams(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));

    // assert
    expect(result, const Right(tProducts));
    verify(mockProductRepository.searchProducts(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Left(ServerFailure(message: 'Search failed')));

    // act
    final result = await usecase(const SearchProductsParams(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));

    // assert
    expect(result, const Left(ServerFailure(message: 'Search failed')));
    verify(mockProductRepository.searchProducts(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return empty list when no products found', () async {
    // arrange
    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(const SearchProductsParams(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));

    // assert
    expect(result, const Right([]));
    verify(mockProductRepository.searchProducts(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return network failure when device is offline', () async {
    // arrange
    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

    // act
    final result = await usecase(const SearchProductsParams(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));

    // assert
    expect(result, const Left(NetworkFailure(message: 'No internet connection')));
    verify(mockProductRepository.searchProducts(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return cache failure when no cached data available', () async {
    // arrange
    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Left(CacheFailure(message: 'No cached search results')));

    // act
    final result = await usecase(const SearchProductsParams(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));

    // assert
    expect(result, const Left(CacheFailure(message: 'No cached search results')));
    verify(mockProductRepository.searchProducts(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should handle empty search query', () async {
    // arrange
    const emptyQuery = '';
    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(const SearchProductsParams(
      query: emptyQuery,
      page: tPage,
      limit: tLimit,
    ));

    // assert
    expect(result, const Right([]));
    verify(mockProductRepository.searchProducts(
      query: emptyQuery,
      page: tPage,
      limit: tLimit,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should handle search with special characters', () async {
    // arrange
    const specialQuery = 'apple & orange!';
    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Right(tProducts));

    // act
    final result = await usecase(const SearchProductsParams(
      query: specialQuery,
      page: tPage,
      limit: tLimit,
    ));

    // assert
    expect(result, const Right(tProducts));
    verify(mockProductRepository.searchProducts(
      query: specialQuery,
      page: tPage,
      limit: tLimit,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should handle search with different pagination', () async {
    // arrange
    const tPage2 = 2;
    const tLimit50 = 50;
    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Right(tProducts));

    // act
    final result = await usecase(const SearchProductsParams(
      query: tQuery,
      page: tPage2,
      limit: tLimit50,
    ));

    // assert
    expect(result, const Right(tProducts));
    verify(mockProductRepository.searchProducts(
      query: tQuery,
      page: tPage2,
      limit: tLimit50,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should handle search with null pagination parameters', () async {
    // arrange
    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Right(tProducts));

    // act
    final result = await usecase(const SearchProductsParams(
      query: tQuery,
      page: null,
      limit: null,
    ));

    // assert
    expect(result, const Right(tProducts));
    verify(mockProductRepository.searchProducts(
      query: tQuery,
      page: null,
      limit: null,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should handle search with multiple matching products', () async {
    // arrange
    const tProduct2 = Product(
      id: 'test-product-id-2',
      name: 'Apple MacBook',
      description: 'Apple MacBook Pro with M1 chip',
      price: 1299.99,
      discountPercentage: 5.0,
      rating: 4.8,
      reviewCount: 200,
      mainImageUrl: 'https://example.com/macbook.jpg',
      inStock: true,
      stockQuantity: 25,
      categoryId: 'electronics',
      brand: 'Apple',
    );

    const tMultipleProducts = [tProduct, tProduct2];

    when(mockProductRepository.searchProducts(
      query: anyNamed('query'),
      page: anyNamed('page'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => const Right(tMultipleProducts));

    // act
    final result = await usecase(const SearchProductsParams(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));

    // assert
    expect(result, const Right(tMultipleProducts));
    result.fold(
      (failure) => fail('Should return products'),
      (products) {
        expect(products.length, 2);
        expect(products[0].name, 'Apple iPhone');
        expect(products[1].name, 'Apple MacBook');
      },
    );
    verify(mockProductRepository.searchProducts(
      query: tQuery,
      page: tPage,
      limit: tLimit,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });
}
