import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/wishlist_item.dart';
import '../repositories/wishlist_repository.dart';

/// Use case to add a product to the wishlist
class AddToWishlistUseCase implements UseCase<WishlistItem, AddToWishlistParams> {
  final WishlistRepository repository;

  AddToWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, WishlistItem>> call(AddToWishlistParams params) {
    return repository.addToWishlist(params.productId);
  }
}

/// Parameters for [AddToWishlistUseCase]
class AddToWishlistParams extends Equatable {
  final String productId;

  const AddToWishlistParams({required this.productId});

  @override
  List<Object> get props => [productId];
} 