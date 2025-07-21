import 'package:dartz/dartz.dart';
import '../entities/cart_item.dart';
import '../entities/product.dart';
import '../../core/errors/failures.dart';

/// Cart repository interface defining methods for cart operations
abstract class CartRepository {
  /// Get all cart items
  /// Returns a [Either] with a [Failure] or a list of [CartItem] entities
  Future<Either<Failure, List<CartItem>>> getCartItems();

  /// Add a product to the cart
  /// Returns a [Either] with a [Failure] or a [CartItem] entity
  Future<Either<Failure, CartItem>> addToCart({
    required Product product,
    required int quantity,
  });

  /// Remove an item from the cart
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> removeFromCart({
    required String cartItemId,
  });

  /// Update the quantity of an item in the cart
  /// Returns a [Either] with a [Failure] or a [CartItem] entity
  Future<Either<Failure, CartItem>> updateQuantity({
    required String cartItemId,
    required int quantity,
  });

  /// Clear the cart
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> clearCart();

  /// Get the total price of all items in the cart
  /// Returns a [Either] with a [Failure] or a [double] representing the total price
  Future<Either<Failure, double>> getTotalPrice();

  /// Get the total number of items in the cart
  /// Returns a [Either] with a [Failure] or an [int] representing the total count
  Future<Either<Failure, int>> getItemCount();

  /// Check if a product is in the cart
  /// Returns a [Either] with a [Failure] or a [bool] indicating if the product is in the cart
  Future<Either<Failure, bool>> isInCart({
    required String productId,
  });

  /// Sync local cart with database (lazy sync strategy)
  /// Returns a [Either] with a [Failure] or a [bool] indicating sync success
  /// This should be called when user navigates to cart or initiates checkout
  Future<Either<Failure, bool>> syncCartWithDatabase();
}