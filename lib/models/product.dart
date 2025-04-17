import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String imageUrl;
  final List<String>? additionalImages;
  final bool isInStock;
  final int stockQuantity;
  final List<String> categories;
  final String? categoryId;
  final double rating;
  final int reviewCount;
  final String brand;
  final DateTime dateAdded;
  final Map<String, dynamic> attributes;
  final bool isFeatured;
  final bool isOnSale;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.imageUrl,
    this.additionalImages,
    required this.isInStock,
    required this.stockQuantity,
    required this.categories,
    this.categoryId,
    required this.rating,
    required this.reviewCount,
    required this.brand,
    required this.dateAdded,
    this.attributes = const {},
    this.isFeatured = false,
    this.isOnSale = false,
  });

  // Getters
  String get imageUrls => imageUrl;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  double? get discountPercentage => discountPrice != null 
    ? ((price - discountPrice!) / price * 100).roundToDouble()
    : null;
  DateTime? get createdAt => dateAdded;

  double get discountedPrice => discountPrice ?? price;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    discountPrice,
    imageUrl,
    additionalImages,
    isInStock,
    stockQuantity,
    categories,
    categoryId,
    rating,
    reviewCount,
    brand,
    dateAdded,
    attributes,
    isFeatured,
    isOnSale,
  ];

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? imageUrl,
    List<String>? additionalImages,
    bool? isInStock,
    int? stockQuantity,
    List<String>? categories,
    String? categoryId,
    double? rating,
    int? reviewCount,
    String? brand,
    DateTime? dateAdded,
    Map<String, dynamic>? attributes,
    bool? isFeatured,
    bool? isOnSale,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      isInStock: isInStock ?? this.isInStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      categories: categories ?? this.categories,
      categoryId: categoryId ?? this.categoryId,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      brand: brand ?? this.brand,
      dateAdded: dateAdded ?? this.dateAdded,
      attributes: attributes ?? this.attributes,
      isFeatured: isFeatured ?? this.isFeatured,
      isOnSale: isOnSale ?? this.isOnSale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'image_url': imageUrl,
      'additional_images': additionalImages,
      'is_in_stock': isInStock,
      'stock_quantity': stockQuantity,
      'categories': categories,
      'category_id': categoryId,
      'rating': rating,
      'review_count': reviewCount,
      'brand': brand,
      'date_added': dateAdded.toIso8601String(),
      'attributes': attributes,
      'is_featured': isFeatured,
      'is_on_sale': isOnSale,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String,
      additionalImages: (json['additional_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isInStock: json['is_in_stock'] as bool,
      stockQuantity: json['stock_quantity'] as int,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      categoryId: json['category_id'] as String?,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      brand: json['brand'] as String,
      dateAdded: DateTime.parse(json['date_added'] as String),
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      isFeatured: json['is_featured'] as bool? ?? false,
      isOnSale: json['is_on_sale'] as bool? ?? false,
    );
  }
} 