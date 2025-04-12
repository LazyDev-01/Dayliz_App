import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountedPrice;
  final String imageUrl;
  final List<String>? additionalImages;
  final bool isInStock;
  final int? stockQuantity;
  final List<String>? categories;
  final double? rating;
  final int? reviewCount;
  final String? brand;
  final DateTime? dateAdded;
  final Map<String, dynamic>? attributes;

  const Product({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.discountedPrice,
    required this.imageUrl,
    this.additionalImages,
    this.isInStock = true,
    this.stockQuantity,
    this.categories,
    this.rating,
    this.reviewCount,
    this.brand,
    this.dateAdded,
    this.attributes,
  });

  // Check if product has a discount
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  // Calculate discount percentage
  int get discountPercentage {
    if (!hasDiscount) return 0;
    return ((price - discountedPrice!) / price * 100).round();
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountedPrice,
    String? imageUrl,
    List<String>? additionalImages,
    bool? isInStock,
    int? stockQuantity,
    List<String>? categories,
    double? rating,
    int? reviewCount,
    String? brand,
    DateTime? dateAdded,
    Map<String, dynamic>? attributes,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      isInStock: isInStock ?? this.isInStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      brand: brand ?? this.brand,
      dateAdded: dateAdded ?? this.dateAdded,
      attributes: attributes ?? this.attributes,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      discountedPrice: json['discounted_price'] != null 
          ? (json['discounted_price'] as num).toDouble() 
          : null,
      imageUrl: json['image_url'],
      additionalImages: json['additional_images'] != null 
          ? List<String>.from(json['additional_images']) 
          : null,
      isInStock: json['is_in_stock'] ?? true,
      stockQuantity: json['stock_quantity'],
      categories: json['categories'] != null 
          ? List<String>.from(json['categories']) 
          : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'],
      brand: json['brand'],
      dateAdded: json['date_added'] != null 
          ? DateTime.parse(json['date_added']) 
          : null,
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discounted_price': discountedPrice,
      'image_url': imageUrl,
      'additional_images': additionalImages,
      'is_in_stock': isInStock,
      'stock_quantity': stockQuantity,
      'categories': categories,
      'rating': rating,
      'review_count': reviewCount,
      'brand': brand,
      'date_added': dateAdded?.toIso8601String(),
      'attributes': attributes,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    discountedPrice,
    imageUrl,
    additionalImages,
    isInStock,
    stockQuantity,
    categories,
    rating,
    reviewCount,
    brand,
    dateAdded,
    attributes,
  ];
} 