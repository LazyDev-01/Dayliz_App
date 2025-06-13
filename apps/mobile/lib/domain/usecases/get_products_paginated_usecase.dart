import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination_models.dart';

/// Use case to get products with pagination support
class GetProductsPaginatedUseCase {
  final ProductRepository repository;

  GetProductsPaginatedUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a [PaginatedResponse] of [Product] entities
  Future<Either<Failure, PaginatedResponse<Product>>> call(GetProductsPaginatedParams params) {
    return repository.getProductsPaginated(
      pagination: params.pagination,
      categoryId: params.categoryId,
      subcategoryId: params.subcategoryId,
      searchQuery: params.searchQuery,
      sortBy: params.sortBy,
      ascending: params.ascending,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
    );
  }
}

/// Parameters for the GetProductsPaginatedUseCase
class GetProductsPaginatedParams extends Equatable {
  final PaginationParams? pagination;
  final String? categoryId;
  final String? subcategoryId;
  final String? searchQuery;
  final String? sortBy;
  final bool? ascending;
  final double? minPrice;
  final double? maxPrice;

  const GetProductsPaginatedParams({
    this.pagination,
    this.categoryId,
    this.subcategoryId,
    this.searchQuery,
    this.sortBy,
    this.ascending,
    this.minPrice,
    this.maxPrice,
  });

  /// Create params for subcategory listing
  factory GetProductsPaginatedParams.forSubcategory({
    required String subcategoryId,
    PaginationParams? pagination,
    String? sortBy,
    bool? ascending,
  }) {
    return GetProductsPaginatedParams(
      subcategoryId: subcategoryId,
      pagination: pagination ?? const PaginationParams.defaultProducts(),
      sortBy: sortBy ?? 'created_at',
      ascending: ascending ?? false,
    );
  }

  /// Create params for category listing
  factory GetProductsPaginatedParams.forCategory({
    required String categoryId,
    PaginationParams? pagination,
    String? sortBy,
    bool? ascending,
  }) {
    return GetProductsPaginatedParams(
      categoryId: categoryId,
      pagination: pagination ?? const PaginationParams.defaultProducts(),
      sortBy: sortBy ?? 'created_at',
      ascending: ascending ?? false,
    );
  }

  /// Create params for search
  factory GetProductsPaginatedParams.forSearch({
    required String searchQuery,
    PaginationParams? pagination,
    String? sortBy,
    bool? ascending,
  }) {
    return GetProductsPaginatedParams(
      searchQuery: searchQuery,
      pagination: pagination ?? const PaginationParams.search(),
      sortBy: sortBy ?? 'created_at',
      ascending: ascending ?? false,
    );
  }

  /// Create params for all products
  factory GetProductsPaginatedParams.all({
    PaginationParams? pagination,
    String? sortBy,
    bool? ascending,
  }) {
    return GetProductsPaginatedParams(
      pagination: pagination ?? const PaginationParams.defaultProducts(),
      sortBy: sortBy ?? 'created_at',
      ascending: ascending ?? false,
    );
  }

  /// Create next page params
  GetProductsPaginatedParams nextPage() {
    return GetProductsPaginatedParams(
      pagination: pagination?.nextPage(),
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      searchQuery: searchQuery,
      sortBy: sortBy,
      ascending: ascending,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  /// Create previous page params
  GetProductsPaginatedParams previousPage() {
    return GetProductsPaginatedParams(
      pagination: pagination?.previousPage(),
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      searchQuery: searchQuery,
      sortBy: sortBy,
      ascending: ascending,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  @override
  List<Object?> get props => [
        pagination,
        categoryId,
        subcategoryId,
        searchQuery,
        sortBy,
        ascending,
        minPrice,
        maxPrice,
      ];

  @override
  String toString() => 'GetProductsPaginatedParams(pagination: $pagination, subcategoryId: $subcategoryId, categoryId: $categoryId)';
}
