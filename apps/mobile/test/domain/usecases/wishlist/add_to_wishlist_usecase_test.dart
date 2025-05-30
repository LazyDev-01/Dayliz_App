import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/wishlist_item.dart';
import 'package:dayliz_app/domain/repositories/wishlist_repository.dart';
import 'package:dayliz_app/domain/usecases/add_to_wishlist_usecase.dart';

// Manual mock class
class MockWishlistRepository extends Mock implements WishlistRepository {}

void main() {
  late AddToWishlistUseCase usecase;
  late MockWishlistRepository mockWishlistRepository;

  setUp(() {
    mockWishlistRepository = MockWishlistRepository();
    usecase = AddToWishlistUseCase(mockWishlistRepository);
  });

  const tProductId = 'test-product-id';
  final tWishlistItem = WishlistItem(
    id: 'test-wishlist-item-id',
    productId: tProductId,
    dateAdded: DateTime.now(),
  );

  test('should add product to wishlist from the repository', () async {
    // arrange
    when(mockWishlistRepository.addToWishlist(any))
        .thenAnswer((_) async => Right(tWishlistItem));

    // act
    final result = await usecase(const AddToWishlistParams(productId: tProductId));

    // assert
    expect(result, Right(tWishlistItem));
    verify(mockWishlistRepository.addToWishlist(tProductId));
    verifyNoMoreInteractions(mockWishlistRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockWishlistRepository.addToWishlist(any))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(const AddToWishlistParams(productId: tProductId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(mockWishlistRepository.addToWishlist(tProductId));
    verifyNoMoreInteractions(mockWishlistRepository);
  });

  test('should return failure when product id is empty', () async {
    // arrange
    const emptyProductId = '';
    when(mockWishlistRepository.addToWishlist(any))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Invalid product ID')));

    // act
    final result = await usecase(const AddToWishlistParams(productId: emptyProductId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Invalid product ID')));
    verify(mockWishlistRepository.addToWishlist(emptyProductId));
    verifyNoMoreInteractions(mockWishlistRepository);
  });

  test('should return network failure when device is offline', () async {
    // arrange
    when(mockWishlistRepository.addToWishlist(any))
        .thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

    // act
    final result = await usecase(const AddToWishlistParams(productId: tProductId));

    // assert
    expect(result, const Left(NetworkFailure(message: 'No internet connection')));
    verify(mockWishlistRepository.addToWishlist(tProductId));
    verifyNoMoreInteractions(mockWishlistRepository);
  });

  test('should return cache failure when local storage fails', () async {
    // arrange
    when(mockWishlistRepository.addToWishlist(any))
        .thenAnswer((_) async => const Left(CacheFailure(message: 'Local storage error')));

    // act
    final result = await usecase(const AddToWishlistParams(productId: tProductId));

    // assert
    expect(result, const Left(CacheFailure(message: 'Local storage error')));
    verify(mockWishlistRepository.addToWishlist(tProductId));
    verifyNoMoreInteractions(mockWishlistRepository);
  });

  test('should handle duplicate product addition gracefully', () async {
    // arrange
    when(mockWishlistRepository.addToWishlist(any))
        .thenAnswer((_) async => Right(tWishlistItem));

    // act
    final result = await usecase(const AddToWishlistParams(productId: tProductId));

    // assert
    expect(result, Right(tWishlistItem));
    verify(mockWishlistRepository.addToWishlist(tProductId));
    verifyNoMoreInteractions(mockWishlistRepository);
  });
}
