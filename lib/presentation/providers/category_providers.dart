import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/dependency_injection.dart' as di;
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

// This file is being phased out in favor of clean_category_providers.dart
// It's maintained temporarily for backward compatibility

// State providers
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);
final categoryFiltersProvider = StateProvider<Map<String, bool>>((ref) => {});

// Repository provider
final categoryRepositoryProvider = Provider((_) => di.sl<CategoryRepository>());

// Use case providers
final getCategoriesUseCaseProvider = Provider(
  (ref) => GetCategoriesUseCase(ref.watch(categoryRepositoryProvider)),
);

final getCategoriesWithSubcategoriesUseCaseProvider = Provider(
  (ref) => GetCategoriesWithSubcategoriesUseCase(
    ref.watch(categoryRepositoryProvider),
  ),
);

// Categories providers
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final useCase = ref.watch(getCategoriesUseCaseProvider);
  final result = await useCase(NoParams());
  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});

final categoriesWithSubcategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final useCase = ref.watch(getCategoriesWithSubcategoriesUseCaseProvider);
  final result = await useCase(NoParams());
  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});

// Filtered categories provider
final filteredCategoriesProvider = Provider<List<Category>>((ref) {
  final categoriesAsync = ref.watch(categoriesWithSubcategoriesProvider);
  final filters = ref.watch(categoryFiltersProvider);
  
  return categoriesAsync.when(
    data: (categories) {
      if (filters.isEmpty || filters.values.every((isActive) => !isActive)) {
        return categories;
      }
      
      return categories.where((category) {
        return filters[category.id] ?? false;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Selected category provider
final selectedCategoryProvider = Provider<Category?>((ref) {
  final categoriesAsync = ref.watch(categoriesWithSubcategoriesProvider);
  final selectedId = ref.watch(selectedCategoryIdProvider);
  
  if (selectedId == null) {
    return null;
  }
  
  return categoriesAsync.when(
    data: (categories) {
      try {
        return categories.firstWhere((category) => category.id == selectedId);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider to track loading state for categories
final categoriesLoadingProvider = StateProvider<bool>((ref) => false);

// Provider to track error message for categories
final categoriesErrorProvider = StateProvider<String?>((ref) => null);

// Provider for getting a category by ID
final categoryByIdProvider = FutureProvider.family<Category, String>((ref, id) async {
  // Reset error
  ref.read(categoriesErrorProvider.notifier).state = null;
  
  // Set loading state
  ref.read(categoriesLoadingProvider.notifier).state = true;
  
  try {
    final result = await di.sl<GetCategoryByIdUseCase>()(GetCategoryByIdParams(id: id));
    
    return result.fold(
      (failure) {
        ref.read(categoriesErrorProvider.notifier).state = _mapFailureToMessage(failure);
        throw _mapFailureToMessage(failure);
      },
      (category) {
        // Reset loading
        ref.read(categoriesLoadingProvider.notifier).state = false;
        return category;
      },
    );
  } catch (e) {
    // Reset loading on error
    ref.read(categoriesLoadingProvider.notifier).state = false;
    ref.read(categoriesErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

// Provider for getting subcategories for a category
final subcategoriesProvider = FutureProvider.family<List<SubCategory>, String>((ref, categoryId) async {
  // Reset error
  ref.read(categoriesErrorProvider.notifier).state = null;
  
  // Set loading state
  ref.read(categoriesLoadingProvider.notifier).state = true;
  
  try {
    final result = await di.sl<GetSubcategoriesUseCase>()(GetSubcategoriesParams(categoryId: categoryId));
    
    return result.fold(
      (failure) {
        ref.read(categoriesErrorProvider.notifier).state = _mapFailureToMessage(failure);
        throw _mapFailureToMessage(failure);
      },
      (subcategories) {
        // Reset loading
        ref.read(categoriesLoadingProvider.notifier).state = false;
        return subcategories;
      },
    );
  } catch (e) {
    // Reset loading on error
    ref.read(categoriesLoadingProvider.notifier).state = false;
    ref.read(categoriesErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

// Helper function to map failures to user-friendly messages
String _mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure:
      return 'Server error occurred. Please try again later.';
    case NetworkFailure:
      return 'Network error. Please check your internet connection.';
    case CacheFailure:
      return 'Cache error. Please restart the app.';
    default:
      return 'An unexpected error occurred.';
  }
} 