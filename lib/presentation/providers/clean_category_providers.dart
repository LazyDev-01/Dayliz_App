import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

import '../../di/dependency_injection.dart' as di;
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

// State for the categories
class CategoriesState {
  final bool isLoading;
  final String? errorMessage;
  final List<Category> categories;
  final Category? selectedCategory;

  const CategoriesState({
    this.isLoading = false,
    this.errorMessage,
    this.categories = const [],
    this.selectedCategory,
  });

  CategoriesState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Category>? categories,
    Category? selectedCategory,
    bool clearError = false,
    bool clearSelectedCategory = false,
  }) {
    return CategoriesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      categories: categories ?? this.categories,
      selectedCategory: clearSelectedCategory ? null : selectedCategory ?? this.selectedCategory,
    );
  }
}

// Notifier to manage the categories state
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final GetCategoriesWithSubcategoriesUseCase getCategoriesWithSubcategoriesUseCase;
  final GetCategoryByIdUseCase getCategoryByIdUseCase;

  CategoriesNotifier({
    required this.getCategoriesWithSubcategoriesUseCase,
    required this.getCategoryByIdUseCase,
  }) : super(const CategoriesState());

  // Load all categories with subcategories
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getCategoriesWithSubcategoriesUseCase(NoParams());
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (categories) {
        state = state.copyWith(
          isLoading: false,
          categories: categories,
        );
      },
    );
  }

  // Load a specific category by ID
  Future<void> loadCategoryById(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getCategoryByIdUseCase(GetCategoryByIdParams(id: id));
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      (category) {
        state = state.copyWith(
          isLoading: false,
          selectedCategory: category,
        );
      },
    );
  }

  // Select a category from the already loaded categories
  void selectCategory(String? id) {
    if (id == null) {
      state = state.copyWith(clearSelectedCategory: true);
      return;
    }

    try {
      final category = state.categories.firstWhere((cat) => cat.id == id);
      state = state.copyWith(selectedCategory: category);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Category not found',
      );
    }
  }

  // Clear the selected category
  void clearSelectedCategory() {
    state = state.copyWith(clearSelectedCategory: true);
  }

  // Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Providers
final categoryRepositoryProvider = Provider((_) => di.sl<CategoryRepository>());

final getCategoriesUseCaseProvider = Provider(
  (ref) => GetCategoriesUseCase(ref.watch(categoryRepositoryProvider)),
);

final getCategoriesWithSubcategoriesUseCaseProvider = Provider(
  (ref) => GetCategoriesWithSubcategoriesUseCase(ref.watch(categoryRepositoryProvider)),
);

final getCategoryByIdUseCaseProvider = Provider(
  (ref) => GetCategoryByIdUseCase(ref.watch(categoryRepositoryProvider)),
);

final categoriesNotifierProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>(
  (ref) => CategoriesNotifier(
    getCategoriesWithSubcategoriesUseCase: ref.watch(getCategoriesWithSubcategoriesUseCaseProvider),
    getCategoryByIdUseCase: ref.watch(getCategoryByIdUseCaseProvider),
  ),
);

// Selector providers for easier state access
final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesNotifierProvider).categories;
});

final selectedCategoryProvider = Provider<Category?>((ref) {
  return ref.watch(categoriesNotifierProvider).selectedCategory;
});

final categoryLoadingProvider = Provider<bool>((ref) {
  return ref.watch(categoriesNotifierProvider).isLoading;
});

final categoryErrorProvider = Provider<String?>((ref) {
  return ref.watch(categoriesNotifierProvider).errorMessage;
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