import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../core/errors/failures.dart';
import '../../core/models/pagination_models.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../mock/mock_products.dart';
import '../models/product_model.dart';

/// Mock implementation of the ProductRepository for testing and development
class ProductRepositoryMockImpl implements ProductRepository {
  /// Get a list of products with optional filters
  @override
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
  }) async {
    try {
      debugPrint('ProductRepositoryMockImpl: Returning mock products');
      final products = MockProducts.getMockProducts();

      // Convert to ProductModel which extends Product
      final productModels = products.map((product) =>
        ProductModel.fromProduct(product)
      ).toList();

      return Right(productModels);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get products: ${e.toString()}'));
    }
  }

  /// Get a product by ID
  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      debugPrint('ProductRepositoryMockImpl: Returning mock product for ID: $id');
      final mockProducts = MockProducts.getMockProducts();
      final product = mockProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => mockProducts.first, // Fallback to first product if ID not found
      );

      // Convert to ProductModel which extends Product
      final productModel = ProductModel.fromProduct(product);

      return Right(productModel);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get product: ${e.toString()}'));
    }
  }

  /// Get featured products
  @override
  Future<Either<Failure, List<Product>>> getFeaturedProducts({int? limit}) async {
    try {
      debugPrint('ProductRepositoryMockImpl: Returning mock featured products');
      final products = MockProducts.getMockProducts().take(limit ?? 5).toList();

      // Convert to ProductModel which extends Product
      final productModels = products.map((product) =>
        ProductModel.fromProduct(product)
      ).toList();

      return Right(productModels);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get featured products: ${e.toString()}'));
    }
  }

  /// Get products on sale
  @override
  Future<Either<Failure, List<Product>>> getProductsOnSale({
    int? page,
    int? limit,
  }) async {
    try {
      debugPrint('ProductRepositoryMockImpl: Returning mock sale products');
      final products = MockProducts.getMockProducts()
          .where((p) => p.discountPercentage != null)
          .take(limit ?? 5)
          .toList();

      // Convert to ProductModel which extends Product
      final productModels = products.map((product) =>
        ProductModel.fromProduct(product)
      ).toList();

      return Right(productModels);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get sale products: ${e.toString()}'));
    }
  }

  /// Get related products
  @override
  Future<Either<Failure, List<Product>>> getRelatedProducts({
    required String productId,
    int? limit,
  }) async {
    try {
      debugPrint('ProductRepositoryMockImpl: Returning mock related products for ID: $productId');
      final products = MockProducts.getMockProducts()
          .where((p) => p.id != productId)
          .take(limit ?? 4)
          .toList();

      // Convert to ProductModel which extends Product
      final productModels = products.map((product) =>
        ProductModel.fromProduct(product)
      ).toList();

      return Right(productModels);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get related products: ${e.toString()}'));
    }
  }

  /// Search products
  @override
  Future<Either<Failure, List<Product>>> searchProducts({
    required String query,
    int? page,
    int? limit,
  }) async {
    try {
      debugPrint('ProductRepositoryMockImpl: Searching mock products with query: $query');
      final products = MockProducts.getMockProducts()
          .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.description.toLowerCase().contains(query.toLowerCase()))
          .take(limit ?? 10)
          .toList();

      // Convert to ProductModel which extends Product
      final productModels = products.map((product) =>
        ProductModel.fromProduct(product)
      ).toList();

      return Right(productModels);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to search products: ${e.toString()}'));
    }
  }

  /// Search products within specific scope (subcategory or category)
  @override
  Future<Either<Failure, List<Product>>> searchProductsScoped({
    required String query,
    String? subcategoryId,
    String? categoryId,
    int? page,
    int? limit,
  }) async {
    try {
      debugPrint('ProductRepositoryMockImpl: Scoped search for "$query" (subcategory: $subcategoryId, category: $categoryId)');

      var products = MockProducts.getMockProducts();

      // Apply scope filtering first
      if (subcategoryId != null) {
        products = products.where((p) => p.subcategoryId == subcategoryId).toList();
      } else if (categoryId != null) {
        products = products.where((p) => p.categoryId == categoryId).toList();
      }

      // Then apply search filtering
      final searchResults = products
          .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.description.toLowerCase().contains(query.toLowerCase()))
          .take(limit ?? 10)
          .toList();

      // Convert to ProductModel which extends Product
      final productModels = searchResults.map((product) =>
        ProductModel.fromProduct(product)
      ).toList();

      debugPrint('ProductRepositoryMockImpl: Found ${productModels.length} scoped products');
      return Right(productModels);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to search scoped products: ${e.toString()}'));
    }
  }

  /// Get products with pagination (mock implementation)
  @override
  Future<Either<Failure, PaginatedResponse<Product>>> getProductsPaginated({
    PaginationParams? pagination,
    String? categoryId,
    String? subcategoryId,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      // Mock implementation - return simple paginated response
      final products = MockProducts.getMockProducts().take(10).toList();
      final productModels = products.map((product) => ProductModel.fromProduct(product)).toList();

      final response = PaginatedResponse<Product>(
        data: productModels,
        meta: const PaginationMeta(
          currentPage: 1,
          totalPages: 1,
          totalItems: 10,
          itemsPerPage: 10,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      );

      return Right(response);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get paginated products: ${e.toString()}'));
    }
  }

  /// Get products by category
  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(String categoryId) async {
    try {
      debugPrint('ProductRepositoryMockImpl: Returning mock products for category: $categoryId');
      final products = MockProducts.getMockProducts()
          .where((p) => p.categoryId == categoryId)
          .toList();

      // Convert to ProductModel which extends Product
      final productModels = products.map((product) =>
        ProductModel.fromProduct(product)
      ).toList();

      return Right(productModels);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get products by category: ${e.toString()}'));
    }
  }

  /// Get products by IDs
  @override
  Future<Either<Failure, List<Product>>> getProductsByIds(List<String> ids) async {
    try {
      debugPrint('ProductRepositoryMockImpl: Returning mock products for IDs: $ids');
      final products = MockProducts.getMockProducts()
          .where((p) => ids.contains(p.id))
          .toList();

      // Convert to ProductModel which extends Product
      final productModels = products.map((product) =>
        ProductModel.fromProduct(product)
      ).toList();

      return Right(productModels);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get products by IDs: ${e.toString()}'));
    }
  }
}
