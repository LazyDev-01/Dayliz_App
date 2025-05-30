import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../core/errors/exceptions.dart';
import '../models/category_model.dart';
import '../../core/constants/api_endpoints.dart';

/// Abstract class defining the contract for remote category data operations
abstract class CategoryRemoteDataSource {
  /// Calls the API endpoint to get all categories
  ///
  /// Throws a [ServerException] for all error codes
  Future<List<CategoryModel>> getCategories();

  /// Calls the API endpoint to get a specific category by ID
  ///
  /// Throws a [ServerException] for all error codes
  Future<CategoryModel> getCategoryById(String id);

  /// Calls the API endpoint to get all categories with their subcategories
  ///
  /// Throws a [ServerException] for all error codes
  Future<List<CategoryModel>> getCategoriesWithSubcategories();
}

/// Implementation of CategoryRemoteDataSource using HTTP client
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final http.Client client;

  CategoryRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await client.get(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.categories}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw ServerException(
        message: 'Failed to fetch categories',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    final response = await client.get(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.categories}/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return CategoryModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException(
        message: 'Failed to fetch category with id: $id',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<List<CategoryModel>> getCategoriesWithSubcategories() async {
    final response = await client.get(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.categoriesWithSubcategories}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw ServerException(
        message: 'Failed to fetch categories with subcategories',
        statusCode: response.statusCode,
      );
    }
  }

  // For development and testing purposes
  List<CategoryModel> getMockedCategories() {
    return [
      CategoryModel(
        id: '1',
        name: 'Electronics',
        icon: Icons.devices,
        themeColor: Colors.blue,
        imageUrl: 'https://example.com/electronics.jpg',
        subCategories: [
          SubCategoryModel(
            id: '101',
            name: 'Smartphones',
            parentId: '1',
            imageUrl: 'https://example.com/smartphones.jpg',
          ),
          SubCategoryModel(
            id: '102',
            name: 'Laptops',
            parentId: '1',
            imageUrl: 'https://example.com/laptops.jpg',
          ),
        ],
      ),
      CategoryModel(
        id: '2',
        name: 'Clothing',
        icon: Icons.checkroom,
        themeColor: Colors.pink,
        imageUrl: 'https://example.com/clothing.jpg',
        subCategories: [
          SubCategoryModel(
            id: '201',
            name: 'Men',
            parentId: '2',
            imageUrl: 'https://example.com/men.jpg',
          ),
          SubCategoryModel(
            id: '202',
            name: 'Women',
            parentId: '2',
            imageUrl: 'https://example.com/women.jpg',
          ),
        ],
      ),
    ];
  }
}