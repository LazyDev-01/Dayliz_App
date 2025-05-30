import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../repositories/cart_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to remove an item from the cart
class RemoveFromCartUseCase {
  final CartRepository repository;

  RemoveFromCartUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> call(RemoveFromCartParams params) {
    return repository.removeFromCart(
      cartItemId: params.cartItemId,
    );
  }
}

/// Parameters for the RemoveFromCartUseCase
class RemoveFromCartParams extends Equatable {
  final String cartItemId;

  const RemoveFromCartParams({
    required this.cartItemId,
  });

  @override
  List<Object?> get props => [cartItemId];
} 