import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/cart_item.dart';
import '../entities/product.dart';
import '../repositories/cart_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to add a product to the cart
class AddToCartUseCase {
  final CartRepository repository;

  AddToCartUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a [CartItem] entity
  Future<Either<Failure, CartItem>> call(AddToCartParams params) {
    return repository.addToCart(
      product: params.product,
      quantity: params.quantity,
    );
  }
}

/// Parameters for the AddToCartUseCase
class AddToCartParams extends Equatable {
  final Product product;
  final int quantity;

  const AddToCartParams({
    required this.product,
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [product, quantity];
} 