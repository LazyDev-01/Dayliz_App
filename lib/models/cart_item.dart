import 'package:equatable/equatable.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:uuid/uuid.dart';

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String imageUrl;
  final int quantity;
  final Map<String, dynamic> attributes;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.imageUrl,
    required this.quantity,
    this.attributes = const {},
  });

  double get totalPrice => (discountPrice ?? price) * quantity;

  bool get hasDiscount => discountPrice != null;

  @override
  List<Object?> get props => [
        id,
        productId,
        name,
        description,
        price,
        discountPrice,
        imageUrl,
        quantity,
        attributes,
      ];

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? imageUrl,
    int? quantity,
    Map<String, dynamic>? attributes,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      attributes: attributes ?? this.attributes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'image_url': imageUrl,
      'quantity': quantity,
      'attributes': attributes,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String,
      quantity: json['quantity'] as int,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  double get total => price * quantity;
  double get discountedTotal => (discountPrice ?? price) * quantity;
  double get discount => discountPrice != null ? price - discountPrice! : 0;
  double get totalDiscount => discount * quantity;
  
  // Add a product getter to represent the item as a Product
  Product get product => Product(
    id: productId,
    name: name,
    description: description,
    price: price,
    discountPrice: discountPrice,
    imageUrl: imageUrl,
    isInStock: true, // Default to true
    stockQuantity: 100, // Default value
    categories: [], // Empty categories
    rating: 0.0, // Default rating
    reviewCount: 0, // Default review count
    brand: 'Unknown', // Default brand
    dateAdded: DateTime.now(), // Current date
    attributes: attributes,
  );

  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      id: const Uuid().v4(),
      productId: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      discountPrice: product.discountPrice,
      imageUrl: product.imageUrl,
      quantity: quantity,
      attributes: product.attributes,
    );
  }

  Product toProduct() {
    return Product(
      id: productId,
      name: name,
      description: description,
      price: price,
      discountPrice: discountPrice,
      imageUrl: imageUrl,
      isInStock: true,
      stockQuantity: quantity,
      categories: ['Unknown'],
      rating: 0,
      reviewCount: 0,
      brand: 'Unknown',
      dateAdded: DateTime.now(),
      attributes: attributes,
    );
  }
} 