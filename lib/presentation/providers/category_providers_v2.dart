import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../di/dependency_injection.dart' as di;

/// Async provider that ensures dependency injection is complete before accessing repository
final categoryRepositoryAsyncProvider = FutureProvider<CategoryRepository>((ref) async {
  // Wait for dependency injection to complete
  await ref.watch(dependencyInjectionProvider.future);
  return di.sl<CategoryRepository>();
});

/// Provider that ensures dependency injection is fully initialized
final dependencyInjectionProvider = FutureProvider<void>((ref) async {
  try {
    // Check if CategoryRepository is registered, if not initialize clean architecture
    if (!di.sl.isRegistered<CategoryRepository>()) {
      debugPrint('CategoryRepository not registered, initializing clean architecture...');
      await di.initCleanArchitecture();
    }

    // Double-check registration
    if (!di.sl.isRegistered<CategoryRepository>()) {
      throw Exception('CategoryRepository failed to register during initialization');
    }

    debugPrint('Dependency injection initialization completed successfully');
  } catch (e) {
    debugPrint('Error during dependency injection initialization: $e');
    rethrow;
  }
});

/// Async provider for categories that handles the complete flow
final categoriesAsyncProvider = FutureProvider<List<Category>>((ref) async {
  try {
    final repository = await ref.watch(categoryRepositoryAsyncProvider.future);
    final result = await repository.getCategoriesWithSubcategories();

    return result.fold(
      (failure) => throw Exception(_mapFailureToMessage(failure)),
      (categories) => categories,
    );
  } catch (e) {
    throw Exception('Failed to load categories: $e');
  }
});

/// Provider for a specific category by ID
final categoryByIdProvider = FutureProvider.family<Category?, String>((ref, categoryId) async {
  try {
    final repository = await ref.watch(categoryRepositoryAsyncProvider.future);
    final result = await repository.getCategoryById(categoryId);

    return result.fold(
      (failure) => throw Exception(_mapFailureToMessage(failure)),
      (category) => category,
    );
  } catch (e) {
    throw Exception('Failed to load category: $e');
  }
});

/// State notifier for more complex category operations
class CategoryNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  final CategoryRepository _repository;

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.getCategoriesWithSubcategories();

      state = result.fold(
        (failure) => AsyncValue.error(_mapFailureToMessage(failure), StackTrace.current),
        (categories) => AsyncValue.data(categories),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  Future<void> refreshCategories() async {
    // Keep current data while refreshing
    final currentData = state.value;

    try {
      final result = await _repository.getCategoriesWithSubcategories();

      state = result.fold(
        (failure) => AsyncValue.error(_mapFailureToMessage(failure), StackTrace.current),
        (categories) => AsyncValue.data(categories),
      );
    } catch (e, stackTrace) {
      // Restore previous data if refresh fails
      if (currentData != null) {
        state = AsyncValue.data(currentData);
      } else {
        state = AsyncValue.error(e.toString(), stackTrace);
      }
    }
  }
}

/// Convenience providers for easier access to specific states
final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesAsyncProvider).value ?? [];
});

final categoriesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(categoriesAsyncProvider).isLoading;
});

final categoriesErrorProvider = Provider<String?>((ref) {
  final asyncValue = ref.watch(categoriesAsyncProvider);
  return asyncValue.hasError ? asyncValue.error.toString() : null;
});

/// Helper function to map failures to user-friendly messages
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

/// Provider for refreshing categories (useful for pull-to-refresh)
final refreshCategoriesProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(categoriesAsyncProvider);
    await ref.read(categoriesAsyncProvider.future);
  };
});
