import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Parameters for GetSaleProductsUseCase
class GetSaleProductsParams extends Equatable {
  final int? page;
  final int? limit;

  const GetSaleProductsParams({
    this.page,
    this.limit,
  });

  @override
  List<Object?> get props => [page, limit];
}

/// Use case to get products on sale
/// This use case retrieves a list of products that are on sale or have discounts.
class GetSaleProductsUseCase implements UseCase<List<Product>, GetSaleProductsParams> {
  final ProductRepository repository;

  GetSaleProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetSaleProductsParams params) async {
    return await repository.getProductsOnSale(
      page: params.page,
      limit: params.limit,
    );
  }
}
