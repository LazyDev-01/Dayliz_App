import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to get products with optional filtering
class GetProductsUseCase {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> call(GetProductsParams params) {
    return repository.getProducts(
      page: params.page,
      limit: params.limit,
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

/// Parameters for the GetProductsUseCase
class GetProductsParams extends Equatable {
  final int? page;
  final int? limit;
  final String? categoryId;
  final String? subcategoryId;
  final String? searchQuery;
  final String? sortBy;
  final bool? ascending;
  final double? minPrice;
  final double? maxPrice;

  const GetProductsParams({
    this.page,
    this.limit,
    this.categoryId,
    this.subcategoryId,
    this.searchQuery,
    this.sortBy,
    this.ascending,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [
        page,
        limit,
        categoryId,
        subcategoryId,
        searchQuery,
        sortBy,
        ascending,
        minPrice,
        maxPrice,
      ];
} 