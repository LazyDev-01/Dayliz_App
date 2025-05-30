import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/category.dart';

/// Repository interface for category-related operations
abstract class CategoryRepository {
  /// Get all categories
  Future<Either<Failure, List<Category>>> getCategories();

  /// Get a specific category by ID
  Future<Either<Failure, Category>> getCategoryById(String id);

  /// Get all subcategories for a specific category
  Future<Either<Failure, List<SubCategory>>> getSubcategories(String categoryId);

  /// Get all categories with their subcategories pre-loaded
  Future<Either<Failure, List<Category>>> getCategoriesWithSubcategories();
} 