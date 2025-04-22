import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/wishlist_item.dart';
import '../repositories/wishlist_repository.dart';

/// Use case to get all wishlist items for the current user
class GetWishlistItemsUseCase implements UseCase<List<WishlistItem>, NoParams> {
  final WishlistRepository repository;

  GetWishlistItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<WishlistItem>>> call(NoParams params) {
    return repository.getWishlistItems();
  }
} 