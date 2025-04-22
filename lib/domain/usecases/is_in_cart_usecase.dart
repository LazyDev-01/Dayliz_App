import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../repositories/cart_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to check if a product is in the cart
class IsInCartUseCase {
  final CartRepository repository;

  IsInCartUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a [bool] indicating if the product is in the cart
  Future<Either<Failure, bool>> call(IsInCartParams params) {
    return repository.isInCart(
      productId: params.productId,
    );
  }
}

/// Parameters for the IsInCartUseCase
class IsInCartParams extends Equatable {
  final String productId;

  const IsInCartParams({
    required this.productId,
  });

  @override
  List<Object?> get props => [productId];
} 