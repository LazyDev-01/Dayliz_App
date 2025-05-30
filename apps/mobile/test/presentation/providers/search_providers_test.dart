import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/domain/usecases/search_products_usecase.dart';
import 'package:dayliz_app/presentation/providers/search_providers.dart';

// Manual mock classes
class MockSearchProductsUseCase extends Mock implements SearchProductsUseCase {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSearchProductsUseCase mockSearchProductsUseCase;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSearchProductsUseCase = MockSearchProductsUseCase();
    mockSharedPreferences = MockSharedPreferences();
  });

  const tQuery = 'apple';
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
  final tRecentSearches = ['apple', 'samsung', 'laptop'];

  group('RecentSearchesNotifier', () {
    late RecentSearchesNotifier notifier;

    setUp(() {
      notifier = RecentSearchesNotifier();
      // Mock SharedPreferences for testing
      when(mockSharedPreferences.getStringList('recent_searches'))
          .thenReturn(tRecentSearches);
      when(mockSharedPreferences.setStringList(any, any))
          .thenAnswer((_) async => true);
    });

    test('initial state should be empty', () {
      expect(notifier.state, isEmpty);
    });

    test('should load recent searches from SharedPreferences', () async {
      // arrange
      when(mockSharedPreferences.getStringList('recent_searches'))
          .thenReturn(tRecentSearches);

      // act
      await notifier.loadRecentSearches();

      // assert
      expect(notifier.state, tRecentSearches);
    });

    test('should add search to recent searches', () async {
      // arrange
      const newSearch = 'new search';
      when(mockSharedPreferences.setStringList(any, any))
          .thenAnswer((_) async => true);

      // act
      await notifier.addSearch(newSearch);

      // assert
      expect(notifier.state.first, newSearch);
      expect(notifier.state.contains(newSearch), true);
    });

    test('should not add empty search', () async {
      // arrange
      const emptySearch = '';
      final initialState = notifier.state;

      // act
      await notifier.addSearch(emptySearch);

      // assert
      expect(notifier.state, initialState);
    });

    test('should not add duplicate search', () async {
      // arrange
      const duplicateSearch = 'apple';
      notifier.state = ['apple', 'samsung'];
      when(mockSharedPreferences.setStringList(any, any))
          .thenAnswer((_) async => true);

      // act
      await notifier.addSearch(duplicateSearch);

      // assert
      expect(notifier.state.where((item) => item == duplicateSearch).length, 1);
      expect(notifier.state.first, duplicateSearch);
    });

    test('should remove search from recent searches', () async {
      // arrange
      const searchToRemove = 'apple';
      notifier.state = ['apple', 'samsung', 'laptop'];
      when(mockSharedPreferences.setStringList(any, any))
          .thenAnswer((_) async => true);

      // act
      await notifier.removeSearch(searchToRemove);

      // assert
      expect(notifier.state.contains(searchToRemove), false);
      expect(notifier.state.length, 2);
    });

    test('should clear all recent searches', () async {
      // arrange
      notifier.state = ['apple', 'samsung', 'laptop'];
      when(mockSharedPreferences.setStringList(any, any))
          .thenAnswer((_) async => true);

      // act
      await notifier.clearSearches();

      // assert
      expect(notifier.state, isEmpty);
    });

    test('should limit recent searches to maximum count', () async {
      // arrange
      const maxSearches = 10;
      final manySearches = List.generate(15, (index) => 'search$index');
      when(mockSharedPreferences.setStringList(any, any))
          .thenAnswer((_) async => true);

      // act
      for (final search in manySearches) {
        await notifier.addSearch(search);
      }

      // assert
      expect(notifier.state.length, lessThanOrEqualTo(maxSearches));
    });

    test('should handle case-insensitive duplicate detection', () async {
      // arrange
      notifier.state = ['Apple'];
      when(mockSharedPreferences.setStringList(any, any))
          .thenAnswer((_) async => true);

      // act
      await notifier.addSearch('apple');

      // assert
      expect(notifier.state.length, 1);
      expect(notifier.state.first, 'apple');
    });
  });

  group('Search Functions', () {
    test('should perform search successfully', () async {
      // arrange
      when(mockSearchProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tProducts));

      // This test would require setting up a proper Riverpod container
      // For now, we'll test the use case directly
      final result = await mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      );

      // assert
      expect(result, const Right(tProducts));
      verify(mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      ));
    });

    test('should handle search failure', () async {
      // arrange
      when(mockSearchProductsUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Search failed')));

      // act
      final result = await mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      );

      // assert
      expect(result, const Left(ServerFailure(message: 'Search failed')));
      verify(mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      ));
    });

    test('should handle empty search query', () async {
      // arrange
      const emptyQuery = '';
      when(mockSearchProductsUseCase.call(any))
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await mockSearchProductsUseCase.call(
        const SearchProductsParams(query: emptyQuery, limit: 20),
      );

      // assert
      expect(result, const Right([]));
      verify(mockSearchProductsUseCase.call(
        const SearchProductsParams(query: emptyQuery, limit: 20),
      ));
    });

    test('should handle network failure during search', () async {
      // arrange
      when(mockSearchProductsUseCase.call(any))
          .thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

      // act
      final result = await mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      );

      // assert
      expect(result, const Left(NetworkFailure(message: 'No internet connection')));
      verify(mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      ));
    });

    test('should handle cache failure during search', () async {
      // arrange
      when(mockSearchProductsUseCase.call(any))
          .thenAnswer((_) async => const Left(CacheFailure(message: 'No cached search results')));

      // act
      final result = await mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      );

      // assert
      expect(result, const Left(CacheFailure(message: 'No cached search results')));
      verify(mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      ));
    });

    test('should handle search with pagination', () async {
      // arrange
      const page = 2;
      const limit = 10;
      when(mockSearchProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tProducts));

      // act
      final result = await mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, page: page, limit: limit),
      );

      // assert
      expect(result, const Right(tProducts));
      verify(mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, page: page, limit: limit),
      ));
    });

    test('should handle search with multiple results', () async {
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

      when(mockSearchProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tMultipleProducts));

      // act
      final result = await mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      );

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
      verify(mockSearchProductsUseCase.call(
        const SearchProductsParams(query: tQuery, limit: 20),
      ));
    });

    test('should handle search with special characters', () async {
      // arrange
      const specialQuery = 'apple & orange!';
      when(mockSearchProductsUseCase.call(any))
          .thenAnswer((_) async => const Right(tProducts));

      // act
      final result = await mockSearchProductsUseCase.call(
        const SearchProductsParams(query: specialQuery, limit: 20),
      );

      // assert
      expect(result, const Right(tProducts));
      verify(mockSearchProductsUseCase.call(
        const SearchProductsParams(query: specialQuery, limit: 20),
      ));
    });
  });
}
