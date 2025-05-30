import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/wishlist_repository.dart';

/// Use case to clear the wishlist
class ClearWishlistUseCase implements UseCase<bool, NoParams> {
  final WishlistRepository repository;

  ClearWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.clearWishlist();
  }
} 