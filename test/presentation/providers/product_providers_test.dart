import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/domain/usecases/get_products_usecase.dart';
import 'package:dayliz_app/domain/usecases/get_product_by_id_usecase.dart';
import 'package:dayliz_app/presentation/providers/product_providers.dart';

// Manual mock classes
class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}
class MockGetProductByIdUseCase extends Mock implements GetProductByIdUseCase {}

void main() {
  late MockGetProductsUseCase mockGetProductsUseCase;
  late MockGetProductByIdUseCase mockGetProductByIdUseCase;

  setUp(() {
    mockGetProductsUseCase = MockGetProductsUseCase();
    mockGetProductByIdUseCase = MockGetProductByIdUseCase();
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

  group('ProductNotifier', () {
    late ProductNotifier notifier;

    setUp(() {
      notifier = ProductNotifier(mockGetProductsUseCase);
    });

    test('initial state should be ProductInitial', () {
      expect(notifier.state, isA<ProductInitial>());
    });

    test('should emit [ProductLoading, ProductLoaded] when getProducts is successful', () async {
      // arrange
      when(mockGetProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tProductList));

      // act
      await notifier.getProducts(const GetProductsParams(page: 1, limit: 10));

      // assert
      expect(notifier.state, isA<ProductLoaded>());
      final loadedState = notifier.state as ProductLoaded;
      expect(loadedState.products, tProductList);
      verify(mockGetProductsUseCase.call(const GetProductsParams(page: 1, limit: 10)));
    });

    test('should emit [ProductLoading, ProductError] when getProducts fails', () async {
      // arrange
      when(mockGetProductsUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

      // act
      await notifier.getProducts(const GetProductsParams(page: 1, limit: 10));

      // assert
      expect(notifier.state, isA<ProductError>());
      final errorState = notifier.state as ProductError;
      expect(errorState.message, 'Server error');
      verify(mockGetProductsUseCase.call(const GetProductsParams(page: 1, limit: 10)));
    });

    test('should emit [ProductLoading, ProductLoaded] when loadMore is successful', () async {
      // arrange
      // First load initial products
      when(mockGetProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tProductList));
      await notifier.getProducts(const GetProductsParams(page: 1, limit: 10));

      // Setup for loadMore
      const additionalProduct = Product(
        id: 'additional-product-id',
        name: 'Additional Product',
        description: 'Additional Description',
        price: 49.99,
        mainImageUrl: 'https://example.com/additional.jpg',
        inStock: true,
        stockQuantity: 25,
        categoryId: 'test-category-id',
      );
      const additionalProducts = [additionalProduct];

      when(mockGetProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(additionalProducts));

      // act
      await notifier.loadMore(const GetProductsParams(page: 2, limit: 10));

      // assert
      expect(notifier.state, isA<ProductLoaded>());
      final loadedState = notifier.state as ProductLoaded;
      expect(loadedState.products.length, 2); // Original + additional
      expect(loadedState.products, contains(tProduct));
      expect(loadedState.products, contains(additionalProduct));
    });

    test('should emit [ProductLoading, ProductError] when loadMore fails', () async {
      // arrange
      // First load initial products
      when(mockGetProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tProductList));
      await notifier.getProducts(const GetProductsParams(page: 1, limit: 10));

      // Setup for loadMore failure
      when(mockGetProductsUseCase.call(any))
          .thenAnswer((_) async => const Left(NetworkFailure(message: 'Network error')));

      // act
      await notifier.loadMore(const GetProductsParams(page: 2, limit: 10));

      // assert
      expect(notifier.state, isA<ProductError>());
      final errorState = notifier.state as ProductError;
      expect(errorState.message, 'Network error');
    });

    test('should clear products and reset to initial state', () async {
      // arrange
      when(mockGetProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tProductList));
      await notifier.getProducts(const GetProductsParams(page: 1, limit: 10));

      // act
      notifier.clearProducts();

      // assert
      expect(notifier.state, isA<ProductInitial>());
    });
  });

  group('ProductDetailNotifier', () {
    late ProductDetailNotifier notifier;

    setUp(() {
      notifier = ProductDetailNotifier(mockGetProductByIdUseCase);
    });

    test('initial state should be ProductDetailInitial', () {
      expect(notifier.state, isA<ProductDetailInitial>());
    });

    test('should emit [ProductDetailLoading, ProductDetailLoaded] when getProductById is successful', () async {
      // arrange
      when(mockGetProductByIdUseCase.call(any))
          .thenAnswer((_) async => const Right(tProduct));

      // act
      await notifier.getProductById('test-product-id');

      // assert
      expect(notifier.state, isA<ProductDetailLoaded>());
      final loadedState = notifier.state as ProductDetailLoaded;
      expect(loadedState.product, tProduct);
      verify(mockGetProductByIdUseCase.call(const GetProductByIdParams(productId: 'test-product-id')));
    });

    test('should emit [ProductDetailLoading, ProductDetailError] when getProductById fails', () async {
      // arrange
      when(mockGetProductByIdUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Product not found')));

      // act
      await notifier.getProductById('test-product-id');

      // assert
      expect(notifier.state, isA<ProductDetailError>());
      final errorState = notifier.state as ProductDetailError;
      expect(errorState.message, 'Product not found');
      verify(mockGetProductByIdUseCase.call(const GetProductByIdParams(productId: 'test-product-id')));
    });

    test('should clear product detail and reset to initial state', () async {
      // arrange
      when(mockGetProductByIdUseCase.call(any))
          .thenAnswer((_) async => const Right(tProduct));
      await notifier.getProductById('test-product-id');

      // act
      notifier.clearProductDetail();

      // assert
      expect(notifier.state, isA<ProductDetailInitial>());
    });
  });
}
