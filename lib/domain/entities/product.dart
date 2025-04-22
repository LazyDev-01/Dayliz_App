import 'package:equatable/equatable.dart';

/// Product entity class representing a product in the domain layer
class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPercentage;
  final double? rating;
  final int? reviewCount;
  final String mainImageUrl;
  final List<String>? additionalImages;
  final bool inStock;
  final int? stockQuantity;
  final String categoryId;
  final String? subcategoryId;
  final String? brand;
  final Map<String, dynamic>? attributes;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? images;
  final bool onSale;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPercentage,
    this.rating,
    this.reviewCount,
    required this.mainImageUrl,
    this.additionalImages,
    required this.inStock,
    this.stockQuantity,
    required this.categoryId,
    this.subcategoryId,
    this.brand,
    this.attributes,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.images,
    this.onSale = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        discountPercentage,
        rating,
        reviewCount,
        mainImageUrl,
        additionalImages,
        inStock,
        stockQuantity,
        categoryId,
        subcategoryId,
        brand,
        attributes,
        tags,
        createdAt,
        updatedAt,
        images,
        onSale,
      ];

  /// Calculate the discounted price of the product
  double get discountedPrice {
    if (discountPercentage == null || discountPercentage == 0) {
      return price;
    }
    return price * (1 - (discountPercentage! / 100));
  }

  /// Returns a copy of this Product with the given fields replaced
  Product copyWith({
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
    List<String>? images,
    bool? onSale,
  }) {
    return Product(
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
      images: images ?? this.images,
      onSale: onSale ?? this.onSale,
    );
  }
} 