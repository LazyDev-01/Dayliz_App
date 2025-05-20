import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Use case to search products by query
class SearchProductsUseCase implements UseCase<List<Product>, SearchProductsParams> {
  final ProductRepository repository;

  SearchProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(SearchProductsParams params) async {
    return await repository.searchProducts(
      query: params.query,
      page: params.page,
      limit: params.limit,
    );
  }
}

/// Parameters for the SearchProductsUseCase
class SearchProductsParams extends Equatable {
  final String query;
  final int? page;
  final int? limit;

  const SearchProductsParams({
    required this.query,
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [query, page, limit];
}
