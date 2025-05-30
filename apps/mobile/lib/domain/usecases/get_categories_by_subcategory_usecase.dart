import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Use case to get products by subcategory ID
class GetProductsBySubcategoryUseCase implements UseCase<List<Product>, GetProductsBySubcategoryParams> {
  final ProductRepository repository;

  GetProductsBySubcategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetProductsBySubcategoryParams params) async {
    return await repository.getProducts(
      subcategoryId: params.subcategoryId,
      limit: params.limit,
      page: params.page,
      sortBy: params.sortBy,
      ascending: params.ascending,
    );
  }
}

/// Parameters for GetProductsBySubcategoryUseCase
class GetProductsBySubcategoryParams extends Equatable {
  final String subcategoryId;
  final int? limit;
  final int? page;
  final String? sortBy;
  final bool? ascending;

  const GetProductsBySubcategoryParams({
    required this.subcategoryId,
    this.limit,
    this.page,
    this.sortBy,
    this.ascending,
  });

  @override
  List<Object?> get props => [subcategoryId, limit, page, sortBy, ascending];
} 