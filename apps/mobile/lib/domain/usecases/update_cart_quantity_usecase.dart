import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to update the quantity of an item in the cart
class UpdateCartQuantityUseCase {
  final CartRepository repository;

  UpdateCartQuantityUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a [CartItem] entity
  Future<Either<Failure, CartItem>> call(UpdateCartQuantityParams params) {
    return repository.updateQuantity(
      cartItemId: params.cartItemId,
      quantity: params.quantity,
    );
  }
}

/// Parameters for the UpdateCartQuantityUseCase
class UpdateCartQuantityParams extends Equatable {
  final String cartItemId;
  final int quantity;

  const UpdateCartQuantityParams({
    required this.cartItemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [cartItemId, quantity];
} 