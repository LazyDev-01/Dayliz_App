import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetRelatedProductsUseCase implements UseCase<List<Product>, GetRelatedProductsParams> {
  final ProductRepository repository;

  GetRelatedProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetRelatedProductsParams params) async {
    return await repository.getRelatedProducts(
      productId: params.productId,
      limit: params.limit,
    );
  }
}

class GetRelatedProductsParams extends Equatable {
  final String productId;
  final int? limit;

  const GetRelatedProductsParams({
    required this.productId,
    this.limit = 5,
  });

  @override
  List<Object?> get props => [productId, limit];
} 