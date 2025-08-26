import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/cart_item.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/domain/usecases/get_cart_items_usecase.dart';
import 'package:dayliz_app/domain/usecases/add_to_cart_usecase.dart';
import 'package:dayliz_app/domain/usecases/remove_from_cart_usecase.dart';
import 'package:dayliz_app/domain/usecases/update_cart_quantity_usecase.dart';
import 'package:dayliz_app/domain/usecases/clear_cart_usecase.dart';
import 'package:dayliz_app/domain/usecases/get_cart_total_price_usecase.dart';
import 'package:dayliz_app/domain/usecases/get_cart_item_count_usecase.dart';
import 'package:dayliz_app/domain/usecases/is_in_cart_usecase.dart';
import 'package:dayliz_app/presentation/providers/cart_providers.dart';

@GenerateMocks([
  GetCartItemsUseCase,
  AddToCartUseCase,
  RemoveFromCartUseCase,
  UpdateCartQuantityUseCase,
  ClearCartUseCase,
  GetCartTotalPriceUseCase,
  GetCartItemCountUseCase,
  IsInCartUseCase,
])
import 'cart_providers_test.mocks.dart';

void main() {
  late MockGetCartItemsUseCase mockGetCartItemsUseCase;
  late MockAddToCartUseCase mockAddToCartUseCase;
  late MockRemoveFromCartUseCase mockRemoveFromCartUseCase;
  late MockUpdateCartQuantityUseCase mockUpdateCartQuantityUseCase;
  late MockClearCartUseCase mockClearCartUseCase;
  late MockGetCartTotalPriceUseCase mockGetCartTotalPriceUseCase;
  late MockGetCartItemCountUseCase mockGetCartItemCountUseCase;
  late MockIsInCartUseCase mockIsInCartUseCase;

  setUp(() {
    mockGetCartItemsUseCase = MockGetCartItemsUseCase();
    mockAddToCartUseCase = MockAddToCartUseCase();
    mockRemoveFromCartUseCase = MockRemoveFromCartUseCase();
    mockUpdateCartQuantityUseCase = MockUpdateCartQuantityUseCase();
    mockClearCartUseCase = MockClearCartUseCase();
    mockGetCartTotalPriceUseCase = MockGetCartTotalPriceUseCase();
    mockGetCartItemCountUseCase = MockGetCartItemCountUseCase();
    mockIsInCartUseCase = MockIsInCartUseCase();
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
  const tTotalPrice = 199.98;
  const tItemCount = 2;
  const tQuantity = 2;
  const tCartItemId = 'test-cart-item-id';

  group('CartNotifier', () {
    late CartNotifier notifier;

    setUp(() {
      notifier = CartNotifier(
        getCartItemsUseCase: mockGetCartItemsUseCase,
        addToCartUseCase: mockAddToCartUseCase,
        removeFromCartUseCase: mockRemoveFromCartUseCase,
        updateCartQuantityUseCase: mockUpdateCartQuantityUseCase,
        clearCartUseCase: mockClearCartUseCase,
        getCartTotalPriceUseCase: mockGetCartTotalPriceUseCase,
        getCartItemCountUseCase: mockGetCartItemCountUseCase,
        isInCartUseCase: mockIsInCartUseCase,
      );
    });

    test('initial state should have empty cart items', () {
      expect(notifier.state.items, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('should get cart items successfully', () async {
      // arrange
      when(mockGetCartItemsUseCase.call())
          .thenAnswer((_) async => Right(tCartItems));
      when(mockGetCartTotalPriceUseCase.call())
          .thenAnswer((_) async => const Right(tTotalPrice));
      when(mockGetCartItemCountUseCase.call())
          .thenAnswer((_) async => const Right(tItemCount));

      // act
      await notifier.getCartItems();

      // Wait a bit for async operations to complete
      await Future.delayed(const Duration(milliseconds: 10));

      // assert
      expect(notifier.state.items, tCartItems);
      expect(notifier.state.totalPrice, tTotalPrice);
      expect(notifier.state.itemCount, tItemCount);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetCartItemsUseCase.call()).called(1);
    });

    test('should handle error when getting cart items fails', () async {
      // arrange
      when(mockGetCartItemsUseCase.call())
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

      // act
      await notifier.getCartItems();

      // assert
      expect(notifier.state.items, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, 'Server error occurred. Please try again later.');
      verify(mockGetCartItemsUseCase.call()).called(1);
    });

    test('should add product to cart successfully', () async {
      // arrange
      when(mockAddToCartUseCase.call(const AddToCartParams(
        product: tProduct,
        quantity: tQuantity,
      ))).thenAnswer((_) async => Right(tCartItem));
      when(mockGetCartItemsUseCase.call())
          .thenAnswer((_) async => Right(tCartItems));
      when(mockGetCartTotalPriceUseCase.call())
          .thenAnswer((_) async => const Right(tTotalPrice));
      when(mockGetCartItemCountUseCase.call())
          .thenAnswer((_) async => const Right(tItemCount));

      // act
      final result = await notifier.addToCart(product: tProduct, quantity: tQuantity);

      // assert
      expect(result, true);
      expect(notifier.state.items, tCartItems);
      verify(mockAddToCartUseCase.call(const AddToCartParams(
        product: tProduct,
        quantity: tQuantity,
      )));
    });

    test('should handle error when adding to cart fails', () async {
      // arrange
      // Mock lazy initialization
      when(mockGetCartItemsUseCase.call())
          .thenAnswer((_) async => const Right([]));
      when(mockGetCartTotalPriceUseCase.call())
          .thenAnswer((_) async => const Right(0.0));
      when(mockGetCartItemCountUseCase.call())
          .thenAnswer((_) async => const Right(0));

      when(mockAddToCartUseCase.call(const AddToCartParams(
        product: tProduct,
        quantity: tQuantity,
      ))).thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to add to cart')));

      // act
      final result = await notifier.addToCart(product: tProduct, quantity: tQuantity);

      // assert
      expect(result, false);
      expect(notifier.state.errorMessage, 'Server error occurred. Please try again later.');
      verify(mockAddToCartUseCase.call(const AddToCartParams(
        product: tProduct,
        quantity: tQuantity,
      )));
    });

    test('should remove item from cart successfully', () async {
      // arrange
      // Set up initial cart state with the item to be removed
      notifier.state = notifier.state.copyWith(items: tCartItems);

      when(mockRemoveFromCartUseCase.call(const RemoveFromCartParams(
        cartItemId: tCartItemId,
      ))).thenAnswer((_) async => const Right(true));
      when(mockGetCartItemsUseCase.call())
          .thenAnswer((_) async => const Right([]));
      when(mockGetCartTotalPriceUseCase.call())
          .thenAnswer((_) async => const Right(0.0));
      when(mockGetCartItemCountUseCase.call())
          .thenAnswer((_) async => const Right(0));

      // act
      final result = await notifier.removeFromCart(cartItemId: tCartItemId);

      // assert
      expect(result, true);
      expect(notifier.state.items, isEmpty);
      verify(mockRemoveFromCartUseCase.call(const RemoveFromCartParams(
        cartItemId: tCartItemId,
      )));
    });

    test('should update cart item quantity successfully', () async {
      // arrange
      // Set up initial cart state with the item to be updated
      notifier.state = notifier.state.copyWith(items: tCartItems);

      when(mockUpdateCartQuantityUseCase.call(const UpdateCartQuantityParams(
        cartItemId: tCartItemId,
        quantity: tQuantity,
      ))).thenAnswer((_) async => Right(tCartItem));
      when(mockGetCartItemsUseCase.call())
          .thenAnswer((_) async => Right(tCartItems));
      when(mockGetCartTotalPriceUseCase.call())
          .thenAnswer((_) async => const Right(tTotalPrice));
      when(mockGetCartItemCountUseCase.call())
          .thenAnswer((_) async => const Right(tItemCount));

      // act
      final result = await notifier.updateQuantity(
        cartItemId: tCartItemId,
        quantity: tQuantity,
      );

      // assert
      expect(result, true);
      verify(mockUpdateCartQuantityUseCase.call(const UpdateCartQuantityParams(
        cartItemId: tCartItemId,
        quantity: tQuantity,
      )));
    });

    test('should clear cart successfully', () async {
      // arrange
      when(mockClearCartUseCase.call())
          .thenAnswer((_) async => const Right(true));
      when(mockGetCartItemsUseCase.call())
          .thenAnswer((_) async => const Right([]));
      when(mockGetCartTotalPriceUseCase.call())
          .thenAnswer((_) async => const Right(0.0));
      when(mockGetCartItemCountUseCase.call())
          .thenAnswer((_) async => const Right(0));

      // act
      final result = await notifier.clearCart();

      // assert
      expect(result, true);
      expect(notifier.state.items, isEmpty);
      expect(notifier.state.totalPrice, 0.0);
      expect(notifier.state.itemCount, 0);
      verify(mockClearCartUseCase.call());
    });

    test('should check if product is in cart', () async {
      // arrange
      when(mockIsInCartUseCase.call(IsInCartParams(
        productId: tProduct.id,
      ))).thenAnswer((_) async => const Right(true));

      // act
      final result = await notifier.isInCart(productId: tProduct.id);

      // assert
      expect(result, true);
      verify(mockIsInCartUseCase.call(IsInCartParams(
        productId: tProduct.id,
      )));
    });

    test('should return false when product is not in cart', () async {
      // arrange
      when(mockIsInCartUseCase.call(IsInCartParams(
        productId: tProduct.id,
      ))).thenAnswer((_) async => const Right(false));

      // act
      final result = await notifier.isInCart(productId: tProduct.id);

      // assert
      expect(result, false);
      verify(mockIsInCartUseCase.call(IsInCartParams(
        productId: tProduct.id,
      )));
    });
  });
}
