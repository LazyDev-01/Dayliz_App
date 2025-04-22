import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../core/error/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_data_source.dart';
import '../models/category_model.dart';

/// Implementation of the category repository that returns mock data for testing
class CategoryRepositoryImpl implements CategoryRepository {
  final NetworkInfo networkInfo;
  final CategoryRemoteDataSource? remoteDataSource;

  CategoryRepositoryImpl({
    required this.networkInfo,
    this.remoteDataSource,
  });

  // Mock data for testing
  final List<Category> _mockCategories = [
    Category(
      id: '1',
      name: 'Electronics',
      icon: Icons.devices,
      themeColor: Colors.blue,
      displayOrder: 1,
      subCategories: [
        SubCategory(
          id: '101',
          name: 'Smartphones',
          parentId: '1',
          imageUrl: 'https://via.placeholder.com/150',
          displayOrder: 1,
          productCount: 15,
        ),
        SubCategory(
          id: '102',
          name: 'Laptops',
          parentId: '1',
          imageUrl: 'https://via.placeholder.com/150',
          displayOrder: 2,
          productCount: 10,
        ),
      ],
    ),
    Category(
      id: '2',
      name: 'Fashion',
      icon: Icons.checkroom,
      themeColor: Colors.pink,
      displayOrder: 2,
      subCategories: [
        SubCategory(
          id: '201',
          name: 'Men\'s Clothing',
          parentId: '2',
          imageUrl: 'https://via.placeholder.com/150',
          displayOrder: 1,
          productCount: 25,
        ),
        SubCategory(
          id: '202',
          name: 'Women\'s Clothing',
          parentId: '2',
          imageUrl: 'https://via.placeholder.com/150',
          displayOrder: 2,
          productCount: 30,
        ),
      ],
    ),
    Category(
      id: '3',
      name: 'Home & Kitchen',
      icon: Icons.home,
      themeColor: Colors.green,
      displayOrder: 3,
      subCategories: [
        SubCategory(
          id: '301',
          name: 'Appliances',
          parentId: '3',
          imageUrl: 'https://via.placeholder.com/150',
          displayOrder: 1,
          productCount: 20,
        ),
        SubCategory(
          id: '302',
          name: 'Furniture',
          parentId: '3',
          imageUrl: 'https://via.placeholder.com/150',
          displayOrder: 2,
          productCount: 15,
        ),
      ],
    ),
  ];

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    if (remoteDataSource != null) {
      try {
        final categories = await remoteDataSource!.getCategories();
        return Right(categories);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Unexpected error occurred: ${e.toString()}'));
      }
    } else {
      // Return mock data if no remote data source is provided
      if (await networkInfo.isConnected) {
        return Right(_mockCategories);
      } else {
        return Left(NetworkFailure());
      }
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String id) async {
    if (remoteDataSource != null) {
      try {
        final category = await remoteDataSource!.getCategoryById(id);
        return Right(category);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Unexpected error occurred: ${e.toString()}'));
      }
    } else {
      // Return mock data if no remote data source is provided
      if (await networkInfo.isConnected) {
        try {
          final category = _mockCategories.firstWhere(
            (category) => category.id == id,
            orElse: () => throw Exception('Category not found'),
          );
          return Right(category);
        } catch (e) {
          return Left(ServerFailure(message: 'Category not found'));
        }
      } else {
        return Left(NetworkFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<SubCategory>>> getSubcategories(String categoryId) async {
    try {
      if (await networkInfo.isConnected) {
        final category = _mockCategories.firstWhere(
          (category) => category.id == categoryId,
          orElse: () => throw Exception('Category not found'),
        );
        final subcategories = category.subCategories ?? [];
        return Right(subcategories);
      } else {
        return Left(NetworkFailure());
      }
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategoriesWithSubcategories() async {
    if (remoteDataSource != null) {
      try {
        final categories = await remoteDataSource!.getCategoriesWithSubcategories();
        return Right(categories);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Unexpected error occurred: ${e.toString()}'));
      }
    } else {
      // Return mock data if no remote data source is provided
      if (await networkInfo.isConnected) {
        return Right(_mockCategories);
      } else {
        return Left(NetworkFailure());
      }
    }
  }
} 