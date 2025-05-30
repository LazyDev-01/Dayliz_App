import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/domain/repositories/product_repository.dart';
import 'package:dayliz_app/domain/usecases/get_product_by_id_usecase.dart';

// Manual mock class
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetProductByIdUseCase usecase;
  late MockProductRepository mockProductRepository;

  setUp(() {
    mockProductRepository = MockProductRepository();
    usecase = GetProductByIdUseCase(mockProductRepository);
  });

  const tProductId = 'test-product-id';
  const tProduct = Product(
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
    categoryId: 'test-category-id',
    subcategoryId: 'test-subcategory-id',
    brand: 'Test Brand',
  );

  test('should get product by id from the repository', () async {
    // arrange
    when(mockProductRepository.getProductById(any))
        .thenAnswer((_) async => const Right(tProduct));

    // act
    final result = await usecase(const GetProductByIdParams(productId: tProductId));

    // assert
    expect(result, const Right(tProduct));
    verify(mockProductRepository.getProductById(tProductId));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockProductRepository.getProductById(any))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Product not found')));

    // act
    final result = await usecase(const GetProductByIdParams(productId: tProductId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Product not found')));
    verify(mockProductRepository.getProductById(tProductId));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return failure when product id is empty', () async {
    // arrange
    const emptyProductId = '';
    when(mockProductRepository.getProductById(any))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Invalid product ID')));

    // act
    final result = await usecase(const GetProductByIdParams(productId: emptyProductId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Invalid product ID')));
    verify(mockProductRepository.getProductById(emptyProductId));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return network failure when device is offline', () async {
    // arrange
    when(mockProductRepository.getProductById(any))
        .thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

    // act
    final result = await usecase(const GetProductByIdParams(productId: tProductId));

    // assert
    expect(result, const Left(NetworkFailure(message: 'No internet connection')));
    verify(mockProductRepository.getProductById(tProductId));
    verifyNoMoreInteractions(mockProductRepository);
  });

  test('should return cache failure when no cached data available', () async {
    // arrange
    when(mockProductRepository.getProductById(any))
        .thenAnswer((_) async => const Left(CacheFailure(message: 'No cached product data')));

    // act
    final result = await usecase(const GetProductByIdParams(productId: tProductId));

    // assert
    expect(result, const Left(CacheFailure(message: 'No cached product data')));
    verify(mockProductRepository.getProductById(tProductId));
    verifyNoMoreInteractions(mockProductRepository);
  });
}
