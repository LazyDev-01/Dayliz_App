import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Enum for category types
enum CategoryType {
  product,
  service,
}

/// Enum for business models
enum BusinessModel {
  instantDelivery,
  scheduledService,
  booking,
  reservation,
}

/// Enum for availability scope
enum AvailabilityScope {
  zoneBased,
  cityWide,
}

/// Category entity class representing a product category in the domain layer
class Category extends Equatable {
  final String id;
  final String name;
  final IconData icon;
  final Color themeColor;
  final String? imageUrl;
  final int displayOrder;
  final List<SubCategory>? subCategories;

  // New service-related fields
  final CategoryType categoryType;
  final BusinessModel businessModel;
  final AvailabilityScope availabilityScope;
  final bool isActive;
  final bool showInCategoriesScreen;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.themeColor,
    this.imageUrl,
    this.displayOrder = 0,
    this.subCategories,
    this.categoryType = CategoryType.product,
    this.businessModel = BusinessModel.instantDelivery,
    this.availabilityScope = AvailabilityScope.zoneBased,
    this.isActive = true,
    this.showInCategoriesScreen = true,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        themeColor,
        imageUrl,
        displayOrder,
        subCategories,
        categoryType,
        businessModel,
        availabilityScope,
        isActive,
        showInCategoriesScreen,
      ];

  /// Returns a copy of this Category with the given fields replaced
  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? themeColor,
    String? imageUrl,
    int? displayOrder,
    List<SubCategory>? subCategories,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      themeColor: themeColor ?? this.themeColor,
      imageUrl: imageUrl ?? this.imageUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      subCategories: subCategories ?? this.subCategories,
    );
  }
}

/// SubCategory entity class representing a product subcategory in the domain layer
class SubCategory extends Equatable {
  final String id;
  final String name;
  final String parentId;
  final String? imageUrl;
  final String? iconName;
  final int displayOrder;
  final int productCount;

  const SubCategory({
    required this.id,
    required this.name,
    required this.parentId,
    this.imageUrl,
    this.iconName,
    this.displayOrder = 0,
    this.productCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        parentId,
        imageUrl,
        iconName,
        displayOrder,
        productCount,
      ];

  /// Returns a copy of this SubCategory with the given fields replaced
  SubCategory copyWith({
    String? id,
    String? name,
    String? parentId,
    String? imageUrl,
    String? iconName,
    int? displayOrder,
    int? productCount,
  }) {
    return SubCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      displayOrder: displayOrder ?? this.displayOrder,
      productCount: productCount ?? this.productCount,
    );
  }
} 