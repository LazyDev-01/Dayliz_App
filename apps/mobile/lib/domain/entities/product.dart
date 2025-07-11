import 'package:equatable/equatable.dart';

/// Product entity class representing a product in the domain layer
class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? retailPrice;
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
  final String? weight;
  final Map<String, dynamic>? attributes;
  final Map<String, dynamic>? nutritionalInfo;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? images;
  final bool onSale;
  final String? categoryName;
  final String? subcategoryName;
  final String? vendorId;
  final String? vendorName;
  final String? vendorFssaiLicense;
  final String? vendorAddress;
  final bool nutriActive;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.retailPrice,
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
    this.weight,
    this.attributes,
    this.nutritionalInfo,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.images,
    this.onSale = false,
    this.categoryName,
    this.subcategoryName,
    this.vendorId,
    this.vendorName,
    this.vendorFssaiLicense,
    this.vendorAddress,
    this.nutriActive = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        retailPrice,
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
        weight,
        attributes,
        nutritionalInfo,
        tags,
        createdAt,
        updatedAt,
        images,
        onSale,
        categoryName,
        subcategoryName,
        vendorId,
        vendorName,
        vendorFssaiLicense,
        vendorAddress,
        nutriActive,
      ];

  /// Get the original price (MRP) of the product
  double get originalPrice {
    return price; // price field contains MRP
  }



  /// Get the discounted price of the product
  double get discountedPrice {
    // Use retail price if available, otherwise calculate from MRP and discount
    if (retailPrice != null) {
      return retailPrice!;
    }

    if (discountPercentage == null || discountPercentage == 0) {
      return price; // No discount, return MRP
    }
    // Calculate discounted price: MRP - (MRP * discount / 100)
    return price - (price * discountPercentage! / 100);
  }

  /// Returns a copy of this Product with the given fields replaced
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? retailPrice,
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
    String? weight,
    Map<String, dynamic>? attributes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? images,
    bool? onSale,
    String? categoryName,
    String? subcategoryName,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      retailPrice: retailPrice ?? this.retailPrice,
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
      weight: weight ?? this.weight,
      attributes: attributes ?? this.attributes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      onSale: onSale ?? this.onSale,
      categoryName: categoryName ?? this.categoryName,
      subcategoryName: subcategoryName ?? this.subcategoryName,
    );
  }
}