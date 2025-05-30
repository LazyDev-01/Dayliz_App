import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/cart_item.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/domain/repositories/cart_repository.dart';
import 'package:dayliz_app/domain/usecases/get_cart_items_usecase.dart';

// Manual mock class
class MockCartRepository extends Mock implements CartRepository {}

void main() {
  late GetCartItemsUseCase usecase;
  late MockCartRepository mockCartRepository;

  setUp(() {
    mockCartRepository = MockCartRepository();
    usecase = GetCartItemsUseCase(mockCartRepository);
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
    brand: 'Test Brand',
  );

  final tCartItem = CartItem(
    id: 'test-cart-item-id',
    product: tProduct,
    quantity: 2,
    addedAt: DateTime.now(),
  );

  final tCartItems = [tCartItem];

  test('should get cart items from the repository', () async {
    // arrange
    when(mockCartRepository.getCartItems())
        .thenAnswer((_) async => Right(tCartItems));

    // act
    final result = await usecase.call();

    // assert
    expect(result, Right(tCartItems));
    verify(mockCartRepository.getCartItems());
    verifyNoMoreInteractions(mockCartRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockCartRepository.getCartItems())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase.call();

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(mockCartRepository.getCartItems());
    verifyNoMoreInteractions(mockCartRepository);
  });

  test('should return empty list when no cart items found', () async {
    // arrange
    when(mockCartRepository.getCartItems())
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase.call();

    // assert
    expect(result, const Right([]));
    verify(mockCartRepository.getCartItems());
    verifyNoMoreInteractions(mockCartRepository);
  });

  test('should return network failure when device is offline', () async {
    // arrange
    when(mockCartRepository.getCartItems())
        .thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

    // act
    final result = await usecase.call();

    // assert
    expect(result, const Left(NetworkFailure(message: 'No internet connection')));
    verify(mockCartRepository.getCartItems());
    verifyNoMoreInteractions(mockCartRepository);
  });

  test('should return cache failure when no cached data available', () async {
    // arrange
    when(mockCartRepository.getCartItems())
        .thenAnswer((_) async => const Left(CacheFailure(message: 'No cached cart data')));

    // act
    final result = await usecase.call();

    // assert
    expect(result, const Left(CacheFailure(message: 'No cached cart data')));
    verify(mockCartRepository.getCartItems());
    verifyNoMoreInteractions(mockCartRepository);
  });
}
