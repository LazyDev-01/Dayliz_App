import 'package:dartz/dartz.dart';
import '../repositories/cart_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to clear the cart
class ClearCartUseCase {
  final CartRepository repository;

  ClearCartUseCase(this.repository);

  /// Execute the use case
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> call() {
    return repository.clearCart();
  }
}