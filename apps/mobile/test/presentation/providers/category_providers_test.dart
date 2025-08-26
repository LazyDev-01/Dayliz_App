import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayliz_app/domain/entities/category.dart';

void main() {
  // Since the current implementation uses FutureProvider directly with Supabase,
  // we'll create a simple test that verifies the basic structure.
  // For comprehensive testing, we would need to mock Supabase or create a proper
  // StateNotifier implementation.

  const tCategory = Category(
    id: '1',
    name: 'Electronics',
    icon: Icons.devices,
    themeColor: Colors.blue,
    displayOrder: 1,
    categoryType: CategoryType.product,
    businessModel: BusinessModel.instantDelivery,
    availabilityScope: AvailabilityScope.zoneBased,
    isActive: true,
    showInCategoriesScreen: true,
    subCategories: [
      SubCategory(
        id: '101',
        name: 'Smartphones',
        parentId: '1',
        imageUrl: 'https://via.placeholder.com/150',
        displayOrder: 1,
      ),
    ],
  );

  const tCategories = [tCategory];

  group('Category Entity Tests', () {
    test('should create category with all required fields', () {
      // act & assert
      expect(tCategory.id, '1');
      expect(tCategory.name, 'Electronics');
      expect(tCategory.icon, Icons.devices);
      expect(tCategory.themeColor, Colors.blue);
      expect(tCategory.displayOrder, 1);
      expect(tCategory.categoryType, CategoryType.product);
      expect(tCategory.businessModel, BusinessModel.instantDelivery);
      expect(tCategory.availabilityScope, AvailabilityScope.zoneBased);
      expect(tCategory.isActive, true);
      expect(tCategory.showInCategoriesScreen, true);
      expect(tCategory.subCategories, isNotNull);
      expect(tCategory.subCategories!.length, 1);
    });

    test('should create subcategory with all required fields', () {
      // arrange
      final subcategory = tCategory.subCategories!.first;

      // act & assert
      expect(subcategory.id, '101');
      expect(subcategory.name, 'Smartphones');
      expect(subcategory.parentId, '1');
      expect(subcategory.imageUrl, 'https://via.placeholder.com/150');
      expect(subcategory.displayOrder, 1);
    });

    test('should handle category equality correctly', () {
      // arrange
      const category1 = Category(
        id: '1',
        name: 'Electronics',
        icon: Icons.devices,
        themeColor: Colors.blue,
        displayOrder: 1,
        categoryType: CategoryType.product,
        businessModel: BusinessModel.instantDelivery,
        availabilityScope: AvailabilityScope.zoneBased,
        isActive: true,
        showInCategoriesScreen: true,
      );

      const category2 = Category(
        id: '1',
        name: 'Electronics',
        icon: Icons.devices,
        themeColor: Colors.blue,
        displayOrder: 1,
        categoryType: CategoryType.product,
        businessModel: BusinessModel.instantDelivery,
        availabilityScope: AvailabilityScope.zoneBased,
        isActive: true,
        showInCategoriesScreen: true,
      );

      // act & assert
      expect(category1, equals(category2));
      expect(category1.hashCode, equals(category2.hashCode));
    });

    test('should handle subcategory equality correctly', () {
      // arrange
      const subcategory1 = SubCategory(
        id: '101',
        name: 'Smartphones',
        parentId: '1',
        imageUrl: 'https://via.placeholder.com/150',
        displayOrder: 1,
      );

      const subcategory2 = SubCategory(
        id: '101',
        name: 'Smartphones',
        parentId: '1',
        imageUrl: 'https://via.placeholder.com/150',
        displayOrder: 1,
      );

      // act & assert
      expect(subcategory1, equals(subcategory2));
      expect(subcategory1.hashCode, equals(subcategory2.hashCode));
    });

    test('should create category with different enum values', () {
      // arrange & act
      const serviceCategory = Category(
        id: '2',
        name: 'Laundry Services',
        icon: Icons.local_laundry_service,
        themeColor: Colors.green,
        displayOrder: 2,
        categoryType: CategoryType.service,
        businessModel: BusinessModel.scheduledService,
        availabilityScope: AvailabilityScope.cityWide,
        isActive: true,
        showInCategoriesScreen: false,
      );

      // assert
      expect(serviceCategory.categoryType, CategoryType.service);
      expect(serviceCategory.businessModel, BusinessModel.scheduledService);
      expect(serviceCategory.availabilityScope, AvailabilityScope.cityWide);
      expect(serviceCategory.showInCategoriesScreen, false);
    });
  });

  group('Category Provider Integration Tests', () {
    test('should have proper category structure for testing', () {
      // This test verifies that our test data structure is valid
      // and can be used for integration testing with the actual providers

      // act & assert
      expect(tCategories, isNotEmpty);
      expect(tCategories.first.subCategories, isNotNull);
      expect(tCategories.first.subCategories!.isNotEmpty, true);

      // Verify the category has all required fields for Supabase mapping
      final category = tCategories.first;
      expect(category.id, isNotEmpty);
      expect(category.name, isNotEmpty);
      expect(category.displayOrder, greaterThanOrEqualTo(0));
      expect(category.categoryType, isNotNull);
      expect(category.businessModel, isNotNull);
      expect(category.availabilityScope, isNotNull);
    });
  });
}
