import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/usecases/usecase.dart';
import 'package:dayliz_app/domain/entities/category.dart';
import 'package:dayliz_app/domain/usecases/get_categories_usecase.dart';
import 'package:dayliz_app/presentation/providers/clean_category_providers.dart';

// Manual mock classes
class MockGetCategoriesWithSubcategoriesUseCase extends Mock implements GetCategoriesWithSubcategoriesUseCase {}
class MockGetCategoryByIdUseCase extends Mock implements GetCategoryByIdUseCase {}

void main() {
  late MockGetCategoriesWithSubcategoriesUseCase mockGetCategoriesWithSubcategoriesUseCase;
  late MockGetCategoryByIdUseCase mockGetCategoryByIdUseCase;

  setUp(() {
    mockGetCategoriesWithSubcategoriesUseCase = MockGetCategoriesWithSubcategoriesUseCase();
    mockGetCategoryByIdUseCase = MockGetCategoryByIdUseCase();
  });

  const tCategory = Category(
    id: '1',
    name: 'Electronics',
    icon: Icons.devices,
    themeColor: Colors.blue,
    displayOrder: 1,
    subCategories: [
      SubCategory(
        id: '101',
        name: 'Smartphones',
        parentId: '1',
        imageUrl: 'https://via.placeholder.com/150',
        displayOrder: 1,
        productCount: 15,
      ),
    ],
  );

  const tCategories = [tCategory];
  const tCategoryId = '1';

  group('CategoriesNotifier', () {
    late CategoriesNotifier notifier;

    setUp(() {
      notifier = CategoriesNotifier(
        getCategoriesWithSubcategoriesUseCase: mockGetCategoriesWithSubcategoriesUseCase,
        getCategoryByIdUseCase: mockGetCategoryByIdUseCase,
      );
    });

    test('initial state should be correct', () {
      expect(notifier.state.categories, isEmpty);
      expect(notifier.state.selectedCategory, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('should load categories successfully', () async {
      // arrange
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Right(tCategories));

      // act
      await notifier.loadCategories();

      // assert
      expect(notifier.state.categories, tCategories);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetCategoriesWithSubcategoriesUseCase.call(NoParams()));
    });

    test('should handle error when loading categories fails', () async {
      // arrange
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

      // act
      await notifier.loadCategories();

      // assert
      expect(notifier.state.categories, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, 'Server error');
      verify(mockGetCategoriesWithSubcategoriesUseCase.call(NoParams()));
    });

    test('should handle network failure when loading categories', () async {
      // arrange
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

      // act
      await notifier.loadCategories();

      // assert
      expect(notifier.state.categories, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, 'No internet connection');
      verify(mockGetCategoriesWithSubcategoriesUseCase.call(NoParams()));
    });

    test('should handle cache failure when loading categories', () async {
      // arrange
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Left(CacheFailure(message: 'No cached data')));

      // act
      await notifier.loadCategories();

      // assert
      expect(notifier.state.categories, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, 'No cached data');
      verify(mockGetCategoriesWithSubcategoriesUseCase.call(NoParams()));
    });

    test('should select category successfully', () async {
      // arrange
      when(mockGetCategoryByIdUseCase.call(any))
          .thenAnswer((_) async => const Right(tCategory));

      // act
      await notifier.selectCategory(tCategoryId);

      // assert
      expect(notifier.state.selectedCategory, tCategory);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetCategoryByIdUseCase.call(const GetCategoryByIdParams(id: tCategoryId)));
    });

    test('should handle error when selecting category fails', () async {
      // arrange
      when(mockGetCategoryByIdUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Category not found')));

      // act
      await notifier.selectCategory(tCategoryId);

      // assert
      expect(notifier.state.selectedCategory, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, 'Category not found');
      verify(mockGetCategoryByIdUseCase.call(const GetCategoryByIdParams(id: tCategoryId)));
    });

    test('should clear selected category', () async {
      // arrange - first select a category
      when(mockGetCategoryByIdUseCase.call(any))
          .thenAnswer((_) async => const Right(tCategory));
      await notifier.selectCategory(tCategoryId);

      // act
      notifier.clearSelectedCategory();

      // assert
      expect(notifier.state.selectedCategory, isNull);
      expect(notifier.state.errorMessage, isNull);
    });

    test('should clear error message', () async {
      // arrange - first create an error
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));
      await notifier.loadCategories();

      // act
      notifier.clearError();

      // assert
      expect(notifier.state.errorMessage, isNull);
    });

    test('should set loading state correctly during operations', () async {
      // arrange
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async {
        // Verify loading state is true during the operation
        expect(notifier.state.isLoading, true);
        return const Right(tCategories);
      });

      // act
      await notifier.loadCategories();

      // assert
      expect(notifier.state.isLoading, false);
    });

    test('should refresh categories successfully', () async {
      // arrange
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Right(tCategories));

      // act
      await notifier.refreshCategories();

      // assert
      expect(notifier.state.categories, tCategories);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      verify(mockGetCategoriesWithSubcategoriesUseCase.call(NoParams()));
    });

    test('should get category by id from loaded categories', () async {
      // arrange - first load categories
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Right(tCategories));
      await notifier.loadCategories();

      // act
      final category = notifier.getCategoryById(tCategoryId);

      // assert
      expect(category, tCategory);
    });

    test('should return null when getting category by id that does not exist', () async {
      // arrange - first load categories
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Right(tCategories));
      await notifier.loadCategories();

      // act
      final category = notifier.getCategoryById('999');

      // assert
      expect(category, isNull);
    });

    test('should get subcategories for a category', () async {
      // arrange - first load categories
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Right(tCategories));
      await notifier.loadCategories();

      // act
      final subcategories = notifier.getSubcategories(tCategoryId);

      // assert
      expect(subcategories, isNotEmpty);
      expect(subcategories.first.parentId, tCategoryId);
    });

    test('should return empty list when getting subcategories for non-existent category', () async {
      // arrange - first load categories
      when(mockGetCategoriesWithSubcategoriesUseCase.call(any))
          .thenAnswer((_) async => const Right(tCategories));
      await notifier.loadCategories();

      // act
      final subcategories = notifier.getSubcategories('999');

      // assert
      expect(subcategories, isEmpty);
    });
  });
}
