import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to get products from a specific subcategory with optional filtering
class GetProductsBySubcategoryUseCase {
  final ProductRepository repository;

  GetProductsBySubcategoryUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> call(GetProductsBySubcategoryParams params) {
    return repository.getProducts(
      subcategoryId: params.subcategoryId,
      page: params.page,
      limit: params.limit,
      sortBy: params.sortBy,
      ascending: params.ascending,
    );
  }
}

/// Parameters for the GetProductsBySubcategoryUseCase
class GetProductsBySubcategoryParams extends Equatable {
  final String subcategoryId;
  final int? page;
  final int? limit;
  final String? sortBy;
  final bool? ascending;

  const GetProductsBySubcategoryParams({
    required this.subcategoryId,
    this.page,
    this.limit,
    this.sortBy,
    this.ascending,
  });

  @override
  List<Object?> get props => [
        subcategoryId,
        page,
        limit,
        sortBy,
        ascending,
      ];
} 