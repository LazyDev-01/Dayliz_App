import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/wishlist_repository.dart';

/// Use case to get product details for all wishlist items
class GetWishlistProductsUseCase implements UseCase<List<Product>, NoParams> {
  final WishlistRepository repository;

  GetWishlistProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) {
    return repository.getWishlistProducts();
  }
} 