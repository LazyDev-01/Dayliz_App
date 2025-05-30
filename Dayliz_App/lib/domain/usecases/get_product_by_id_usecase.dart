import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to get a product by ID
class GetProductByIdUseCase {
  final ProductRepository repository;

  GetProductByIdUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a [Product] entity
  Future<Either<Failure, Product>> call(GetProductByIdParams params) {
    return repository.getProductById(params.id);
  }
}

/// Parameters for the GetProductByIdUseCase
class GetProductByIdParams extends Equatable {
  final String id;

  const GetProductByIdParams({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
} 