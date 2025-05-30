import '../../domain/entities/cart_item.dart';
import 'product_model.dart';

/// Cart item model class extending CartItem entity for data layer operations
class CartItemModel extends CartItem {
  const CartItemModel({
    required String id,
    required ProductModel product,
    required int quantity,
    required DateTime addedAt,
  }) : super(
          id: id,
          product: product,
          quantity: quantity,
          addedAt: addedAt,
        );

  /// Create a CartItemModel from a JSON map
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      product: ProductModel.fromJson(json['product']),
      quantity: json['quantity'],
      addedAt: DateTime.parse(json['added_at']),
    );
  }

  /// Convert this CartItemModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': (product as ProductModel).toJson(),
      'quantity': quantity,
      'added_at': addedAt.toIso8601String(),
    };
  }

  /// Create a copy of this CartItemModel with the given fields replaced
  CartItemModel copyWithModel({
    String? id,
    ProductModel? product,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      product: product ?? (this.product as ProductModel),
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
} 