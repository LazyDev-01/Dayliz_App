import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/cart_item.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/domain/repositories/cart_repository.dart';
import 'package:dayliz_app/domain/usecases/add_to_cart_usecase.dart';

@GenerateMocks([CartRepository])
import 'add_to_cart_usecase_test.mocks.dart';

void main() {
  late AddToCartUseCase usecase;
  late MockCartRepository mockCartRepository;

  setUp(() {
    mockCartRepository = MockCartRepository();
    usecase = AddToCartUseCase(mockCartRepository);
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

  const tQuantity = 2;

  test('should add product to cart from the repository', () async {
    // arrange
    when(mockCartRepository.addToCart(
      product: tProduct,
      quantity: tQuantity,
    )).thenAnswer((_) async => Right(tCartItem));

    // act
    final result = await usecase(const AddToCartParams(
      product: tProduct,
      quantity: tQuantity,
    ));

    // assert
    expect(result, Right(tCartItem));
    verify(mockCartRepository.addToCart(
      product: tProduct,
      quantity: tQuantity,
    ));
    verifyNoMoreInteractions(mockCartRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockCartRepository.addToCart(
      product: tProduct,
      quantity: tQuantity,
    )).thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(const AddToCartParams(
      product: tProduct,
      quantity: tQuantity,
    ));

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(mockCartRepository.addToCart(
      product: tProduct,
      quantity: tQuantity,
    ));
    verifyNoMoreInteractions(mockCartRepository);
  });

  test('should return failure when product is out of stock', () async {
    // arrange
    when(mockCartRepository.addToCart(
      product: tProduct,
      quantity: tQuantity,
    )).thenAnswer((_) async => const Left(ServerFailure(message: 'Product out of stock')));

    // act
    final result = await usecase(const AddToCartParams(
      product: tProduct,
      quantity: tQuantity,
    ));

    // assert
    expect(result, const Left(ServerFailure(message: 'Product out of stock')));
    verify(mockCartRepository.addToCart(
      product: tProduct,
      quantity: tQuantity,
    ));
    verifyNoMoreInteractions(mockCartRepository);
  });

  test('should return failure when quantity is invalid', () async {
    // arrange
    const invalidQuantity = 0;
    when(mockCartRepository.addToCart(
      product: tProduct,
      quantity: invalidQuantity,
    )).thenAnswer((_) async => const Left(ServerFailure(message: 'Invalid quantity')));

    // act
    final result = await usecase(const AddToCartParams(
      product: tProduct,
      quantity: invalidQuantity,
    ));

    // assert
    expect(result, const Left(ServerFailure(message: 'Invalid quantity')));
    verify(mockCartRepository.addToCart(
      product: tProduct,
      quantity: invalidQuantity,
    ));
    verifyNoMoreInteractions(mockCartRepository);
  });

  test('should return network failure when device is offline', () async {
    // arrange
    when(mockCartRepository.addToCart(
      product: tProduct,
      quantity: tQuantity,
    )).thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

    // act
    final result = await usecase(const AddToCartParams(
      product: tProduct,
      quantity: tQuantity,
    ));

    // assert
    expect(result, const Left(NetworkFailure(message: 'No internet connection')));
    verify(mockCartRepository.addToCart(
      product: tProduct,
      quantity: tQuantity,
    ));
    verifyNoMoreInteractions(mockCartRepository);
  });

  test('should add product with quantity 1 by default', () async {
    // arrange
    const defaultQuantity = 1;
    when(mockCartRepository.addToCart(
      product: tProduct,
      quantity: defaultQuantity,
    )).thenAnswer((_) async => Right(tCartItem));

    // act
    final result = await usecase(const AddToCartParams(
      product: tProduct,
      quantity: defaultQuantity,
    ));

    // assert
    expect(result, Right(tCartItem));
    verify(mockCartRepository.addToCart(
      product: tProduct,
      quantity: defaultQuantity,
    ));
    verifyNoMoreInteractions(mockCartRepository);
  });
}
