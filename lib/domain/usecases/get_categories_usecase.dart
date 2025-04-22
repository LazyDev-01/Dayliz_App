import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Use case to get a list of categories
class GetCategoriesUseCase implements UseCase<List<Category>, NoParams> {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    return await repository.getCategories();
  }
}

/// Use case to get a list of categories with subcategories pre-loaded
class GetCategoriesWithSubcategoriesUseCase implements UseCase<List<Category>, NoParams> {
  final CategoryRepository repository;

  GetCategoriesWithSubcategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    return await repository.getCategoriesWithSubcategories();
  }
}

/// Use case to get a single category by ID
class GetCategoryByIdUseCase implements UseCase<Category, GetCategoryByIdParams> {
  final CategoryRepository repository;

  GetCategoryByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Category>> call(GetCategoryByIdParams params) async {
    return await repository.getCategoryById(params.id);
  }
}

/// Use case to get subcategories for a specific category
class GetSubcategoriesUseCase implements UseCase<List<SubCategory>, GetSubcategoriesParams> {
  final CategoryRepository repository;

  GetSubcategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<SubCategory>>> call(GetSubcategoriesParams params) async {
    return await repository.getSubcategories(params.categoryId);
  }
}

/// Parameters for GetCategoryByIdUseCase
class GetCategoryByIdParams extends Equatable {
  final String id;

  const GetCategoryByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Parameters for GetSubcategoriesUseCase
class GetSubcategoriesParams extends Equatable {
  final String categoryId;

  const GetSubcategoriesParams({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
} 