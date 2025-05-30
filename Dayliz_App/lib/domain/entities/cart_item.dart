import 'package:equatable/equatable.dart';
import 'product.dart';

/// CartItem entity class representing an item in the shopping cart
class CartItem extends Equatable {
  final String id;
  final Product product;
  final int quantity;
  final DateTime addedAt;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [
        id,
        product,
        quantity,
        addedAt,
      ];

  /// Calculate the total price of this cart item (quantity * product price)
  double get totalPrice {
    return quantity * product.discountedPrice;
  }

  /// Returns a copy of this CartItem with the given fields replaced
  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
} 