import 'package:dartz/dartz.dart';
import '../entities/product.dart';
import '../../core/errors/failures.dart';

/// Product repository interface defining methods for product operations
abstract class ProductRepository {
  /// Get a list of products with optional filters
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> getProducts({
    int? page,
    int? limit,
    String? categoryId,
    String? subcategoryId,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
    double? minPrice,
    double? maxPrice,
  });

  /// Get a single product by ID
  /// Returns a [Either] with a [Failure] or a [Product] entity
  Future<Either<Failure, Product>> getProductById(String id);

  /// Get featured products
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> getFeaturedProducts({
    int? limit,
  });

  /// Get products on sale (with discount)
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> getProductsOnSale({
    int? page,
    int? limit,
  });

  /// Get related products for a specific product
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> getRelatedProducts({
    required String productId,
    int? limit,
  });

  /// Search products by query
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> searchProducts({
    required String query,
    int? page,
    int? limit,
  });
  
  /// Get products by category ID
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> getProductsByCategory(String categoryId);
  
  /// Get products by a list of IDs
  /// Returns a [Either] with a [Failure] or a list of [Product] entities
  Future<Either<Failure, List<Product>>> getProductsByIds(List<String> ids);
} 