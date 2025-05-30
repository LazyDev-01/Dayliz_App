import 'package:dartz/dartz.dart';
import '../repositories/cart_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to get the total number of items in the cart
class GetCartItemCountUseCase {
  final CartRepository repository;

  GetCartItemCountUseCase(this.repository);

  /// Execute the use case
  /// Returns a [Either] with a [Failure] or an [int] representing the total count
  Future<Either<Failure, int>> call() {
    return repository.getItemCount();
  }
} 