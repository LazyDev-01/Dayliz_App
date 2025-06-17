import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Parameters for GetFeaturedProductsUseCase
class GetFeaturedProductsParams extends Equatable {
  final int? limit;

  const GetFeaturedProductsParams({this.limit});

  @override
  List<Object?> get props => [limit];
}

/// Use case to get featured products
/// This use case retrieves a list of featured products, which are typically highlighted on the home screen.
class GetFeaturedProductsUseCase implements UseCase<List<Product>, GetFeaturedProductsParams> {
  final ProductRepository repository;

  GetFeaturedProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(GetFeaturedProductsParams params) async {
    return await repository.getFeaturedProducts(limit: params.limit);
  }
}
