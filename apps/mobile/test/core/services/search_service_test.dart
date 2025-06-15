import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayliz_app/core/services/search_service.dart';
import 'package:dayliz_app/domain/repositories/product_repository.dart';
import 'package:dayliz_app/domain/entities/product.dart';
import 'package:dayliz_app/core/errors/failures.dart';

import 'search_service_test.mocks.dart';

@GenerateMocks([ProductRepository])
void main() {
  late SearchService searchService;
  late MockProductRepository mockProductRepository;

  setUp(() {
    mockProductRepository = MockProductRepository();
    searchService = SearchService(mockProductRepository);
    
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchService', () {
    final testProducts = [
      Product(
        id: '1',
        name: 'Test Product 1',
        description: 'Test Description 1',
        price: 10.0,
        imageUrl: 'test_image_1.jpg',
        categoryId: 'cat1',
        subcategoryId: 'subcat1',
        isAvailable: true,
        stock: 100,
        unit: 'piece',
        weight: 1.0,
        brand: 'Test Brand',
        tags: ['test'],
        nutritionalInfo: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '2',
        name: 'Test Product 2',
        description: 'Test Description 2',
        price: 20.0,
        imageUrl: 'test_image_2.jpg',
        categoryId: 'cat1',
        subcategoryId: 'subcat1',
        isAvailable: true,
        stock: 50,
        unit: 'piece',
        weight: 2.0,
        brand: 'Test Brand',
        tags: ['test'],
        nutritionalInfo: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    test('should return products when search is successful', () async {
      // Arrange
      const query = 'test';
      when(mockProductRepository.searchProducts(
        query: query,
        page: null,
        limit: 20,
      )).thenAnswer((_) async => Right(testProducts));

      // Act
      final result = await searchService.searchProducts(query: query);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure'),
        (products) {
          expect(products.length, 2);
          expect(products[0].name, 'Test Product 1');
          expect(products[1].name, 'Test Product 2');
        },
      );

      verify(mockProductRepository.searchProducts(
        query: query,
        page: null,
        limit: 20,
      )).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const query = 'test';
      const failure = ServerFailure(message: 'Server error');
      when(mockProductRepository.searchProducts(
        query: query,
        page: null,
        limit: 20,
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await searchService.searchProducts(query: query);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (actualFailure) {
          expect(actualFailure.message, 'Server error');
        },
        (products) => fail('Expected failure but got success'),
      );
    });

    test('should return empty list for empty query', () async {
      // Act
      final result = await searchService.searchProducts(query: '');

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure'),
        (products) {
          expect(products.isEmpty, true);
        },
      );

      verifyNever(mockProductRepository.searchProducts(
        query: anyNamed('query'),
        page: anyNamed('page'),
        limit: anyNamed('limit'),
      ));
    });

    test('should cache search results', () async {
      // Arrange
      const query = 'test';
      when(mockProductRepository.searchProducts(
        query: query,
        page: null,
        limit: 20,
      )).thenAnswer((_) async => Right(testProducts));

      // Act - First search
      await searchService.searchProducts(query: query);
      
      // Act - Second search (should use cache)
      final result = await searchService.searchProducts(query: query);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure'),
        (products) {
          expect(products.length, 2);
        },
      );

      // Repository should only be called once due to caching
      verify(mockProductRepository.searchProducts(
        query: query,
        page: null,
        limit: 20,
      )).called(1);
    });

    test('should track search analytics', () async {
      // Arrange
      const query = 'test';
      when(mockProductRepository.searchProducts(
        query: query,
        page: null,
        limit: 20,
      )).thenAnswer((_) async => Right(testProducts));

      // Act
      await searchService.searchProducts(query: query);
      await searchService.searchProducts(query: query);

      // Assert
      final analytics = searchService.getSearchAnalytics();
      expect(analytics[query.toLowerCase()], 2);
    });

    test('should manage search history', () async {
      // Arrange
      const query1 = 'test1';
      const query2 = 'test2';
      when(mockProductRepository.searchProducts(
        query: anyNamed('query'),
        page: anyNamed('page'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Right(testProducts));

      // Act
      await searchService.searchProducts(query: query1);
      await searchService.searchProducts(query: query2);

      // Assert
      final history = searchService.getSearchHistory();
      expect(history.length, 2);
      expect(history[0], query2); // Most recent first
      expect(history[1], query1);
    });

    test('should generate search suggestions', () async {
      // Arrange
      const query1 = 'test product';
      const query2 = 'test item';
      when(mockProductRepository.searchProducts(
        query: anyNamed('query'),
        page: anyNamed('page'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Right(testProducts));

      // Act - Build search history
      await searchService.searchProducts(query: query1);
      await searchService.searchProducts(query: query2);

      // Get suggestions for partial query
      final suggestions = searchService.getSearchSuggestions('test');

      // Assert
      expect(suggestions.isNotEmpty, true);
      expect(suggestions.contains(query1) || suggestions.contains(query2), true);
    });

    test('should clear cache when requested', () {
      // Act
      searchService.clearCache();

      // Assert
      final stats = searchService.getCacheStats();
      expect(stats['cached_queries'], 0);
    });

    test('should provide cache statistics', () async {
      // Arrange
      const query = 'test';
      when(mockProductRepository.searchProducts(
        query: query,
        page: null,
        limit: 20,
      )).thenAnswer((_) async => Right(testProducts));

      // Act
      await searchService.searchProducts(query: query);
      final stats = searchService.getCacheStats();

      // Assert
      expect(stats['cached_queries'], 1);
      expect(stats['cache_size_mb'], isA<double>());
      expect(stats['oldest_cache_entry'], isA<DateTime>());
    });
  });
}
