import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/usecases/usecase.dart';
import 'package:dayliz_app/domain/entities/wishlist_item.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/domain/usecases/get_wishlist_items_usecase.dart';
import 'package:dayliz_app/domain/usecases/get_wishlist_products_usecase.dart';
import 'package:dayliz_app/domain/usecases/add_to_wishlist_usecase.dart';
import 'package:dayliz_app/domain/usecases/remove_from_wishlist_usecase.dart';
import 'package:dayliz_app/domain/usecases/is_in_wishlist_usecase.dart';
import 'package:dayliz_app/domain/usecases/clear_wishlist_usecase.dart';
import 'package:dayliz_app/presentation/providers/wishlist_providers.dart';

// Manual mock classes
class MockGetWishlistItemsUseCase extends Mock implements GetWishlistItemsUseCase {}
class MockGetWishlistProductsUseCase extends Mock implements GetWishlistProductsUseCase {}
class MockAddToWishlistUseCase extends Mock implements AddToWishlistUseCase {}
class MockRemoveFromWishlistUseCase extends Mock implements RemoveFromWishlistUseCase {}
class MockIsInWishlistUseCase extends Mock implements IsInWishlistUseCase {}
class MockClearWishlistUseCase extends Mock implements ClearWishlistUseCase {}

void main() {
  late MockGetWishlistItemsUseCase mockGetWishlistItemsUseCase;
  late MockGetWishlistProductsUseCase mockGetWishlistProductsUseCase;
  late MockAddToWishlistUseCase mockAddToWishlistUseCase;
  late MockRemoveFromWishlistUseCase mockRemoveFromWishlistUseCase;
  late MockIsInWishlistUseCase mockIsInWishlistUseCase;
  late MockClearWishlistUseCase mockClearWishlistUseCase;

  setUp(() {
    mockGetWishlistItemsUseCase = MockGetWishlistItemsUseCase();
    mockGetWishlistProductsUseCase = MockGetWishlistProductsUseCase();
    mockAddToWishlistUseCase = MockAddToWishlistUseCase();
    mockRemoveFromWishlistUseCase = MockRemoveFromWishlistUseCase();
    mockIsInWishlistUseCase = MockIsInWishlistUseCase();
    mockClearWishlistUseCase = MockClearWishlistUseCase();
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

  final tWishlistItem = WishlistItem(
    id: 'test-wishlist-item-id',
    productId: tProduct.id,
    dateAdded: DateTime.now(),
  );

  final tWishlistItems = [tWishlistItem];
  const tProducts = [tProduct];
  const tProductId = 'test-product-id';

  group('WishlistNotifier', () {
    late WishlistNotifier notifier;

    setUp(() {
      notifier = WishlistNotifier(
        getWishlistItemsUseCase: mockGetWishlistItemsUseCase,
        getWishlistProductsUseCase: mockGetWishlistProductsUseCase,
        addToWishlistUseCase: mockAddToWishlistUseCase,
        removeFromWishlistUseCase: mockRemoveFromWishlistUseCase,
        isInWishlistUseCase: mockIsInWishlistUseCase,
        clearWishlistUseCase: mockClearWishlistUseCase,
      );
    });

    test('initial state should have empty wishlist items', () {
      expect(notifier.state.wishlistItems, isEmpty);
      expect(notifier.state.wishlistProducts, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('should get wishlist items successfully', () async {
      // arrange
      when(mockGetWishlistItemsUseCase.call(any))
          .thenAnswer((_) async => Right(tWishlistItems));

      // act
      await notifier.getWishlistItems();

      // assert
      expect(notifier.state.wishlistItems, tWishlistItems);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetWishlistItemsUseCase.call(NoParams()));
    });

    test('should handle error when getting wishlist items fails', () async {
      // arrange
      when(mockGetWishlistItemsUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

      // act
      await notifier.getWishlistItems();

      // assert
      expect(notifier.state.wishlistItems, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, 'Server error');
      verify(mockGetWishlistItemsUseCase.call(NoParams()));
    });

    test('should get wishlist products successfully', () async {
      // arrange
      when(mockGetWishlistProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tProducts));

      // act
      await notifier.getWishlistProducts();

      // assert
      expect(notifier.state.wishlistProducts, tProducts);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetWishlistProductsUseCase.call(NoParams()));
    });

    test('should add product to wishlist successfully', () async {
      // arrange
      when(mockAddToWishlistUseCase.call(any))
          .thenAnswer((_) async => Right(tWishlistItem));
      when(mockGetWishlistItemsUseCase.call(any))
          .thenAnswer((_) async => Right(tWishlistItems));

      // act
      final result = await notifier.addToWishlist(tProductId);

      // assert
      expect(result, true);
      expect(notifier.state.wishlistItems, tWishlistItems);
      verify(mockAddToWishlistUseCase.call(const AddToWishlistParams(productId: tProductId)));
    });

    test('should handle error when adding to wishlist fails', () async {
      // arrange
      when(mockAddToWishlistUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to add to wishlist')));

      // act
      final result = await notifier.addToWishlist(tProductId);

      // assert
      expect(result, false);
      expect(notifier.state.errorMessage, 'Failed to add to wishlist');
      verify(mockAddToWishlistUseCase.call(const AddToWishlistParams(productId: tProductId)));
    });

    test('should remove product from wishlist successfully', () async {
      // arrange
      when(mockRemoveFromWishlistUseCase.call(any))
          .thenAnswer((_) async => const Right(true));
      when(mockGetWishlistItemsUseCase.call(any))
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await notifier.removeFromWishlist(tProductId);

      // assert
      expect(result, true);
      expect(notifier.state.wishlistItems, isEmpty);
      verify(mockRemoveFromWishlistUseCase.call(const RemoveFromWishlistParams(productId: tProductId)));
    });

    test('should handle error when removing from wishlist fails', () async {
      // arrange
      when(mockRemoveFromWishlistUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to remove from wishlist')));

      // act
      final result = await notifier.removeFromWishlist(tProductId);

      // assert
      expect(result, false);
      expect(notifier.state.errorMessage, 'Failed to remove from wishlist');
      verify(mockRemoveFromWishlistUseCase.call(const RemoveFromWishlistParams(productId: tProductId)));
    });

    test('should check if product is in wishlist', () async {
      // arrange
      when(mockIsInWishlistUseCase.call(any))
          .thenAnswer((_) async => const Right(true));

      // act
      final result = await notifier.isInWishlist(tProductId);

      // assert
      expect(result, true);
      verify(mockIsInWishlistUseCase.call(const IsInWishlistParams(productId: tProductId)));
    });

    test('should return false when product is not in wishlist', () async {
      // arrange
      when(mockIsInWishlistUseCase.call(any))
          .thenAnswer((_) async => const Right(false));

      // act
      final result = await notifier.isInWishlist(tProductId);

      // assert
      expect(result, false);
      verify(mockIsInWishlistUseCase.call(const IsInWishlistParams(productId: tProductId)));
    });

    test('should clear wishlist successfully', () async {
      // arrange
      when(mockClearWishlistUseCase.call(any))
          .thenAnswer((_) async => const Right(true));
      when(mockGetWishlistItemsUseCase.call(any))
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await notifier.clearWishlist();

      // assert
      expect(result, true);
      expect(notifier.state.wishlistItems, isEmpty);
      verify(mockClearWishlistUseCase.call(NoParams()));
    });

    test('should handle error when clearing wishlist fails', () async {
      // arrange
      when(mockClearWishlistUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to clear wishlist')));

      // act
      final result = await notifier.clearWishlist();

      // assert
      expect(result, false);
      expect(notifier.state.errorMessage, 'Failed to clear wishlist');
      verify(mockClearWishlistUseCase.call(NoParams()));
    });

    test('should toggle wishlist status correctly', () async {
      // arrange - first check if in wishlist (false), then add
      when(mockIsInWishlistUseCase.call(any))
          .thenAnswer((_) async => const Right(false));
      when(mockAddToWishlistUseCase.call(any))
          .thenAnswer((_) async => Right(tWishlistItem));
      when(mockGetWishlistItemsUseCase.call(any))
          .thenAnswer((_) async => Right(tWishlistItems));

      // act
      final result = await notifier.toggleWishlist(tProductId);

      // assert
      expect(result, true);
      verify(mockIsInWishlistUseCase.call(const IsInWishlistParams(productId: tProductId)));
      verify(mockAddToWishlistUseCase.call(const AddToWishlistParams(productId: tProductId)));
    });

    test('should refresh wishlist successfully', () async {
      // arrange
      when(mockGetWishlistItemsUseCase.call(any))
          .thenAnswer((_) async => Right(tWishlistItems));
      when(mockGetWishlistProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tProducts));

      // act
      await notifier.refreshWishlist();

      // assert
      expect(notifier.state.wishlistItems, tWishlistItems);
      expect(notifier.state.wishlistProducts, tProducts);
      verify(mockGetWishlistItemsUseCase.call(NoParams()));
      verify(mockGetWishlistProductsUseCase.call(NoParams()));
    });

    test('should clear error message', () async {
      // arrange - first create an error
      when(mockGetWishlistItemsUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));
      await notifier.getWishlistItems();

      // act
      notifier.clearError();

      // assert
      expect(notifier.state.errorMessage, isNull);
    });
  });
}
