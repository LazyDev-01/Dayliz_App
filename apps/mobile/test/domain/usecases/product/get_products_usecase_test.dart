import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/domain/repositories/product_repository.dart';
import 'package:dayliz_app/domain/usecases/get_products_usecase.dart';

// Manual mock class
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetProductsUseCase usecase;
  late MockProductRepository mockProductRepository;

  setUp(() {
    mockProductRepository = MockProductRepository();
    usecase = GetProductsUseCase(mockProductRepository);
  });

  const tProduct = Product(
    id: 'test-product-id',
    name: 'Test Product',
    description: 'Test Description',
    price: 99.99,
    discountPercentage: 10.0,
    rating: 4.5,
    reviewCount: 100,
    mainImageUrl: 'https://example.com/image.jpg',
    inStock: true,
    stockQuantity: 50,
    categoryId: 'test-category-id',
    subcategoryId: 'test-subcategory-id',
    brand: 'Test Brand',
  );

  const tProductList = [tProduct];

  test('should get products from the repository', () async {
    // arrange
    when(mockProductRepository.getProducts(
      page: anyNamed('page'),
      limit: anyNamed('limit'),
      categoryId: anyNamed('categoryId'),
      subcategoryId: anyNamed('subcategoryId'),
      searchQuery: anyNamed('searchQuery'),
      sortBy: anyNamed('sortBy'),
      ascending: anyNamed('ascending'),
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
    )).thenAnswer((_) async => const Right(tProductList));

    // act
    final result = await usecase(const GetProductsParams(
      page: 1,
      limit: 10,
      categoryId: 'test-category-id',
    ));

    // assert
    expect(result, const Right(tProductList));
    verify(mockProductRepository.getProducts(
      page: 1,
      limit: 10,
      categoryId: 'test-category-id',
      subcategoryId: null,
      searchQuery: null,
      sortBy: null,
      ascending: null,
      minPrice: null,
      maxPrice: null,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should get products with search query from the repository', () async {
    // arrange
    when(mockProductRepository.getProducts(
      page: anyNamed('page'),
      limit: anyNamed('limit'),
      categoryId: anyNamed('categoryId'),
      subcategoryId: anyNamed('subcategoryId'),
      searchQuery: anyNamed('searchQuery'),
      sortBy: anyNamed('sortBy'),
      ascending: anyNamed('ascending'),
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
    )).thenAnswer((_) async => const Right(tProductList));

    // act
    final result = await usecase(const GetProductsParams(
      page: 1,
      limit: 10,
      searchQuery: 'test query',
    ));

    // assert
    expect(result, const Right(tProductList));
    verify(mockProductRepository.getProducts(
      page: 1,
      limit: 10,
      categoryId: null,
      subcategoryId: null,
      searchQuery: 'test query',
      sortBy: null,
      ascending: null,
      minPrice: null,
      maxPrice: null,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should get products with price filter from the repository', () async {
    // arrange
    when(mockProductRepository.getProducts(
      page: anyNamed('page'),
      limit: anyNamed('limit'),
      categoryId: anyNamed('categoryId'),
      subcategoryId: anyNamed('subcategoryId'),
      searchQuery: anyNamed('searchQuery'),
      sortBy: anyNamed('sortBy'),
      ascending: anyNamed('ascending'),
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
    )).thenAnswer((_) async => const Right(tProductList));

    // act
    final result = await usecase(const GetProductsParams(
      page: 1,
      limit: 10,
      minPrice: 10.0,
      maxPrice: 100.0,
    ));

    // assert
    expect(result, const Right(tProductList));
    verify(mockProductRepository.getProducts(
      page: 1,
      limit: 10,
      categoryId: null,
      subcategoryId: null,
      searchQuery: null,
      sortBy: null,
      ascending: null,
      minPrice: 10.0,
      maxPrice: 100.0,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should get products with sorting from the repository', () async {
    // arrange
    when(mockProductRepository.getProducts(
      page: anyNamed('page'),
      limit: anyNamed('limit'),
      categoryId: anyNamed('categoryId'),
      subcategoryId: anyNamed('subcategoryId'),
      searchQuery: anyNamed('searchQuery'),
      sortBy: anyNamed('sortBy'),
      ascending: anyNamed('ascending'),
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
    )).thenAnswer((_) async => const Right(tProductList));

    // act
    final result = await usecase(const GetProductsParams(
      page: 1,
      limit: 10,
      sortBy: 'price',
      ascending: true,
    ));

    // assert
    expect(result, const Right(tProductList));
    verify(mockProductRepository.getProducts(
      page: 1,
      limit: 10,
      categoryId: null,
      subcategoryId: null,
      searchQuery: null,
      sortBy: 'price',
      ascending: true,
      minPrice: null,
      maxPrice: null,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockProductRepository.getProducts(
      page: anyNamed('page'),
      limit: anyNamed('limit'),
      categoryId: anyNamed('categoryId'),
      subcategoryId: anyNamed('subcategoryId'),
      searchQuery: anyNamed('searchQuery'),
      sortBy: anyNamed('sortBy'),
      ascending: anyNamed('ascending'),
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
    )).thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(const GetProductsParams(
      page: 1,
      limit: 10,
    ));

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(mockProductRepository.getProducts(
      page: 1,
      limit: 10,
      categoryId: null,
      subcategoryId: null,
      searchQuery: null,
      sortBy: null,
      ascending: null,
      minPrice: null,
      maxPrice: null,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return empty list when no products found', () async {
    // arrange
    when(mockProductRepository.getProducts(
      page: anyNamed('page'),
      limit: anyNamed('limit'),
      categoryId: anyNamed('categoryId'),
      subcategoryId: anyNamed('subcategoryId'),
      searchQuery: anyNamed('searchQuery'),
      sortBy: anyNamed('sortBy'),
      ascending: anyNamed('ascending'),
      minPrice: anyNamed('minPrice'),
      maxPrice: anyNamed('maxPrice'),
    )).thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(const GetProductsParams(
      page: 1,
      limit: 10,
    ));

    // assert
    expect(result, const Right([]));
    verify(mockProductRepository.getProducts(
      page: 1,
      limit: 10,
      categoryId: null,
      subcategoryId: null,
      searchQuery: null,
      sortBy: null,
      ascending: null,
      minPrice: null,
      maxPrice: null,
    ));
    verifyNoMoreInteractions(mockProductRepository);
  });
}
