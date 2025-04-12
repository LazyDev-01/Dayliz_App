import 'package:equatable/equatable.dart';
import 'package:dayliz_app/models/product.dart';

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final double? discountedPrice;
  final int quantity;
  final Map<String, dynamic>? attributes;  // For size, color, etc.

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.discountedPrice,
    required this.quantity,
    this.attributes,
  });

  double get total => price * quantity;
  double get discountedTotal => (discountedPrice ?? price) * quantity;
  double get discount => discountedPrice != null ? price - discountedPrice! : 0;
  double get totalDiscount => discount * quantity;
  
  // Add a product getter to represent the item as a Product
  Product get product => Product(
    id: productId,
    name: name,
    price: price,
    discountedPrice: discountedPrice,
    imageUrl: imageUrl,
    attributes: attributes,
  );

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    double? discountedPrice,
    int? quantity,
    Map<String, dynamic>? attributes,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      quantity: quantity ?? this.quantity,
      attributes: attributes ?? this.attributes,
    );
  }

  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      price: product.price,
      discountedPrice: product.discountedPrice,
      quantity: quantity,
      attributes: product.attributes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'discounted_price': discountedPrice,
      'quantity': quantity,
      'attributes': attributes,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      price: json['price'].toDouble(),
      discountedPrice: json['discounted_price']?.toDouble(),
      quantity: json['quantity'],
      attributes: json['attributes'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    name,
    imageUrl,
    price,
    discountedPrice,
    quantity,
    attributes,
  ];
} 