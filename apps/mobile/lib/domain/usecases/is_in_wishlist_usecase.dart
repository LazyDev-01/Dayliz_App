import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/wishlist_repository.dart';

/// Use case to check if a product is in the wishlist
class IsInWishlistUseCase implements UseCase<bool, IsInWishlistParams> {
  final WishlistRepository repository;

  IsInWishlistUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(IsInWishlistParams params) {
    return repository.isInWishlist(params.productId);
  }
}

/// Parameters for [IsInWishlistUseCase]
class IsInWishlistParams extends Equatable {
  final String productId;

  const IsInWishlistParams({required this.productId});

  @override
  List<Object> get props => [productId];
} 