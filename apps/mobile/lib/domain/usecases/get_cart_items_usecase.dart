import 'package:dartz/dartz.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to get all cart items
class GetCartItemsUseCase {
  final CartRepository repository;

  GetCartItemsUseCase(this.repository);

  /// Execute the use case
  /// Returns a [Either] with a [Failure] or a list of [CartItem] entities
  Future<Either<Failure, List<CartItem>>> call() {
    return repository.getCartItems();
  }
} 