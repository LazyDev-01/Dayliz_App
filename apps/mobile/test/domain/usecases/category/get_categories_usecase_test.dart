import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/core/usecases/usecase.dart';
import 'package:dayliz_app/domain/entities/category.dart';
import 'package:dayliz_app/domain/repositories/category_repository.dart';
import 'package:dayliz_app/domain/usecases/get_categories_usecase.dart';

@GenerateMocks([CategoryRepository])
import 'get_categories_usecase_test.mocks.dart';

void main() {
  late GetCategoriesUseCase usecase;
  late GetCategoriesWithSubcategoriesUseCase usecaseWithSub;
  late GetCategoryByIdUseCase usecaseById;
  late MockCategoryRepository mockCategoryRepository;

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    usecase = GetCategoriesUseCase(mockCategoryRepository);
    usecaseWithSub = GetCategoriesWithSubcategoriesUseCase(mockCategoryRepository);
    usecaseById = GetCategoryByIdUseCase(mockCategoryRepository);
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

  group('GetCategoriesUseCase', () {
    test('should get categories from the repository', () async {
      // arrange
      when(mockCategoryRepository.getCategories())
          .thenAnswer((_) async => const Right(tCategories));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, const Right(tCategories));
      verify(mockCategoryRepository.getCategories());
      verifyNoMoreInteractions(mockCategoryRepository);
    });

    test('should return failure when repository call fails', () async {
      // arrange
      when(mockCategoryRepository.getCategories())
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, const Left(ServerFailure(message: 'Server error')));
      verify(mockCategoryRepository.getCategories());
      verifyNoMoreInteractions(mockCategoryRepository);
    });

    test('should return empty list when no categories found', () async {
      // arrange
      when(mockCategoryRepository.getCategories())
          .thenAnswer((_) async => const Right(<Category>[]));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, const Right(<Category>[]));
      verify(mockCategoryRepository.getCategories());
      verifyNoMoreInteractions(mockCategoryRepository);
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockCategoryRepository.getCategories())
          .thenAnswer((_) async => const Left(NetworkFailure()));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, const Left(NetworkFailure()));
      verify(mockCategoryRepository.getCategories());
      verifyNoMoreInteractions(mockCategoryRepository);
    });
  });

  group('GetCategoriesWithSubcategoriesUseCase', () {
    test('should get categories with subcategories from the repository', () async {
      // arrange
      when(mockCategoryRepository.getCategoriesWithSubcategories())
          .thenAnswer((_) async => const Right(tCategories));

      // act
      final result = await usecaseWithSub(NoParams());

      // assert
      expect(result, const Right(tCategories));
      verify(mockCategoryRepository.getCategoriesWithSubcategories());
      verifyNoMoreInteractions(mockCategoryRepository);
    });

    test('should return failure when repository call fails', () async {
      // arrange
      when(mockCategoryRepository.getCategoriesWithSubcategories())
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

      // act
      final result = await usecaseWithSub(NoParams());

      // assert
      expect(result, const Left(ServerFailure(message: 'Server error')));
      verify(mockCategoryRepository.getCategoriesWithSubcategories());
      verifyNoMoreInteractions(mockCategoryRepository);
    });

    test('should return empty list when no categories found', () async {
      // arrange
      when(mockCategoryRepository.getCategoriesWithSubcategories())
          .thenAnswer((_) async => const Right(<Category>[]));

      // act
      final result = await usecaseWithSub(NoParams());

      // assert
      expect(result, const Right(<Category>[]));
      verify(mockCategoryRepository.getCategoriesWithSubcategories());
      verifyNoMoreInteractions(mockCategoryRepository);
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockCategoryRepository.getCategoriesWithSubcategories())
          .thenAnswer((_) async => const Left(NetworkFailure()));

      // act
      final result = await usecaseWithSub(NoParams());

      // assert
      expect(result, const Left(NetworkFailure()));
      verify(mockCategoryRepository.getCategoriesWithSubcategories());
      verifyNoMoreInteractions(mockCategoryRepository);
    });
  });

  group('GetCategoryByIdUseCase', () {
    test('should get category by id from the repository', () async {
      // arrange
      when(mockCategoryRepository.getCategoryById(tCategoryId))
          .thenAnswer((_) async => const Right(tCategory));

      // act
      final result = await usecaseById(const GetCategoryByIdParams(id: tCategoryId));

      // assert
      expect(result, const Right(tCategory));
      verify(mockCategoryRepository.getCategoryById(tCategoryId));
      verifyNoMoreInteractions(mockCategoryRepository);
    });

    test('should return failure when repository call fails', () async {
      // arrange
      when(mockCategoryRepository.getCategoryById(tCategoryId))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Category not found')));

      // act
      final result = await usecaseById(const GetCategoryByIdParams(id: tCategoryId));

      // assert
      expect(result, const Left(ServerFailure(message: 'Category not found')));
      verify(mockCategoryRepository.getCategoryById(tCategoryId));
      verifyNoMoreInteractions(mockCategoryRepository);
    });

    test('should return failure when category id is empty', () async {
      // arrange
      const emptyId = '';
      when(mockCategoryRepository.getCategoryById(emptyId))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Invalid category ID')));

      // act
      final result = await usecaseById(const GetCategoryByIdParams(id: emptyId));

      // assert
      expect(result, const Left(ServerFailure(message: 'Invalid category ID')));
      verify(mockCategoryRepository.getCategoryById(emptyId));
      verifyNoMoreInteractions(mockCategoryRepository);
    });

    test('should return network failure when device is offline', () async {
      // arrange
      when(mockCategoryRepository.getCategoryById(tCategoryId))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      // act
      final result = await usecaseById(const GetCategoryByIdParams(id: tCategoryId));

      // assert
      expect(result, const Left(NetworkFailure()));
      verify(mockCategoryRepository.getCategoryById(tCategoryId));
      verifyNoMoreInteractions(mockCategoryRepository);
    });
  });
}
