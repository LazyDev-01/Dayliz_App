import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/usecases/usecase.dart';
import 'package:dayliz_app/domain/entities/wishlist_item.dart';
import 'package:dayliz_app/domain/repositories/wishlist_repository.dart';
import 'package:dayliz_app/domain/usecases/get_wishlist_items_usecase.dart';

// Manual mock class
class MockWishlistRepository extends Mock implements WishlistRepository {}

void main() {
  late GetWishlistItemsUseCase usecase;
  late MockWishlistRepository mockWishlistRepository;

  setUp(() {
    mockWishlistRepository = MockWishlistRepository();
    usecase = GetWishlistItemsUseCase(mockWishlistRepository);
  });

  final tWishlistItem = WishlistItem(
    id: 'test-wishlist-item-id',
    productId: 'test-product-id',
    dateAdded: DateTime.now(),
  );

  final tWishlistItems = [tWishlistItem];

  test('should get wishlist items from the repository', () async {
    // arrange
    when(mockWishlistRepository.getWishlistItems())
        .thenAnswer((_) async => Right(tWishlistItems));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Right(tWishlistItems));
    verify(mockWishlistRepository.getWishlistItems());
    verifyNoMoreInteractions(mockWishlistRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockWishlistRepository.getWishlistItems())
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(mockWishlistRepository.getWishlistItems());
    verifyNoMoreInteractions(mockWishlistRepository);
  });

  test('should return empty list when no wishlist items found', () async {
    // arrange
    when(mockWishlistRepository.getWishlistItems())
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Right([]));
    verify(mockWishlistRepository.getWishlistItems());
    verifyNoMoreInteractions(mockWishlistRepository);
  });

  test('should return network failure when device is offline', () async {
    // arrange
    when(mockWishlistRepository.getWishlistItems())
        .thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(NetworkFailure(message: 'No internet connection')));
    verify(mockWishlistRepository.getWishlistItems());
    verifyNoMoreInteractions(mockWishlistRepository);
  });

  test('should return cache failure when no cached data available', () async {
    // arrange
    when(mockWishlistRepository.getWishlistItems())
        .thenAnswer((_) async => const Left(CacheFailure(message: 'No cached wishlist data')));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(CacheFailure(message: 'No cached wishlist data')));
    verify(mockWishlistRepository.getWishlistItems());
    verifyNoMoreInteractions(mockWishlistRepository);
  });
}
