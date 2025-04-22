import 'package:dartz/dartz.dart';
import '../entities/wishlist_item.dart';
import '../entities/product.dart';
import '../../core/errors/failures.dart';

/// Repository interface for wishlist operations
abstract class WishlistRepository {
  /// Get all wishlist items for the current user
  /// Returns a [Either] with a [Failure] or a list of [WishlistItem] entities
  Future<Either<Failure, List<WishlistItem>>> getWishlistItems();

  /// Add a product to the wishlist
  /// Returns a [Either] with a [Failure] or a [WishlistItem] entity
  Future<Either<Failure, WishlistItem>> addToWishlist(String productId);

  /// Remove a product from the wishlist
  /// Returns a [Either] with a [Failure] or a boolean indicating success
  Future<Either<Failure, bool>> removeFromWishlist(String productId);

  /// Check if a product is in the wishlist
  /// Returns a [Either] with a [Failure] or a boolean
  Future<Either<Failure, bool>> isInWishlist(String productId);

  /// Clear the wishlist
  /// Returns a [Either] with a [Failure] or a boolean indicating success
  Future<Either<Failure, bool>> clearWishlist();

  /// Get product details for all wishlist items
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> getWishlistProducts();
} 