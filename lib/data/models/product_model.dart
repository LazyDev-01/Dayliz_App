import '../../domain/entities/product.dart';

/// Product model class extending Product entity for data layer operations
class ProductModel extends Product {
  const ProductModel({
    required String id,
    required String name,
    required String description,
    required double price,
    double? discountPercentage,
    double? rating,
    int? reviewCount,
    required String mainImageUrl,
    List<String>? additionalImages,
    required bool inStock,
    int? stockQuantity,
    required String categoryId,
    String? subcategoryId,
    String? brand,
    Map<String, dynamic>? attributes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          name: name,
          description: description,
          price: price,
          discountPercentage: discountPercentage,
          rating: rating,
          reviewCount: reviewCount,
          mainImageUrl: mainImageUrl,
          additionalImages: additionalImages,
          inStock: inStock,
          stockQuantity: stockQuantity,
          categoryId: categoryId,
          subcategoryId: subcategoryId,
          brand: brand,
          attributes: attributes,
          tags: tags,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create a ProductModel from a Product entity
  factory ProductModel.fromProduct(dynamic product) {
    // Ensure we're working with a Product from domain/entities/product.dart
    final domainProduct = product as Product;

    return ProductModel(
      id: domainProduct.id,
      name: domainProduct.name,
      description: domainProduct.description,
      price: domainProduct.price,
      discountPercentage: domainProduct.discountPercentage,
      rating: domainProduct.rating,
      reviewCount: domainProduct.reviewCount,
      mainImageUrl: domainProduct.mainImageUrl,
      additionalImages: domainProduct.additionalImages,
      inStock: domainProduct.inStock,
      stockQuantity: domainProduct.stockQuantity,
      categoryId: domainProduct.categoryId,
      subcategoryId: domainProduct.subcategoryId,
      brand: domainProduct.brand,
      attributes: domainProduct.attributes,
      tags: domainProduct.tags,
      createdAt: domainProduct.createdAt,
      updatedAt: domainProduct.updatedAt,
    );
  }

  /// Create a ProductModel from a JSON map
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      discountPercentage: json['discount_percentage']?.toDouble(),
      rating: json['rating']?.toDouble(),
      reviewCount: json['review_count'],
      mainImageUrl: json['main_image_url'],
      additionalImages: json['additional_images'] != null
          ? List<String>.from(json['additional_images'])
          : null,
      inStock: json['in_stock'] ?? true,
      stockQuantity: json['stock_quantity'],
      categoryId: json['category_id'],
      subcategoryId: json['subcategory_id'],
      brand: json['brand'],
      attributes: json['attributes'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert this ProductModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_percentage': discountPercentage,
      'rating': rating,
      'review_count': reviewCount,
      'main_image_url': mainImageUrl,
      'additional_images': additionalImages,
      'in_stock': inStock,
      'stock_quantity': stockQuantity,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'brand': brand,
      'attributes': attributes,
      'tags': tags,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this ProductModel with the given fields replaced
  ProductModel copyWithModel({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPercentage,
    double? rating,
    int? reviewCount,
    String? mainImageUrl,
    List<String>? additionalImages,
    bool? inStock,
    int? stockQuantity,
    String? categoryId,
    String? subcategoryId,
    String? brand,
    Map<String, dynamic>? attributes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      inStock: inStock ?? this.inStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      brand: brand ?? this.brand,
      attributes: attributes ?? this.attributes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}