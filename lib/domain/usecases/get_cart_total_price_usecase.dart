import 'package:dartz/dartz.dart';
import '../repositories/cart_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to get the total price of the cart
class GetCartTotalPriceUseCase {
  final CartRepository repository;

  GetCartTotalPriceUseCase(this.repository);

  /// Execute the use case
  /// Returns a [Either] with a [Failure] or a [double] representing the total price
  Future<Either<Failure, double>> call() {
    return repository.getTotalPrice();
  }
} 