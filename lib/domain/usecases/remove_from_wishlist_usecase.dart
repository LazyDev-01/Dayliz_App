import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/wishlist_repository.dart';

/// Use case to remove a product from the wishlist
class RemoveFromWishlistUseCase implements UseCase<bool, RemoveFromWishlistParams> {
  final WishlistRepository repository;

  RemoveFromWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(RemoveFromWishlistParams params) {
    return repository.removeFromWishlist(params.productId);
  }
}

/// Parameters for [RemoveFromWishlistUseCase]
class RemoveFromWishlistParams extends Equatable {
  final String productId;

  const RemoveFromWishlistParams({required this.productId});

  @override
  List<Object> get props => [productId];
} 