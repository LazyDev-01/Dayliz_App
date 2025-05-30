import 'package:equatable/equatable.dart';

/// Represents an individual item within an order
class OrderItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? options;
  final String? variantId;
  final String? sku;
  
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.options,
    this.variantId,
    this.sku,
  });
  
  /// Returns a copy of this OrderItem with the given fields replaced with the new values
  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? imageUrl,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    Map<String, dynamic>? options,
    String? variantId,
    String? sku,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      options: options ?? this.options,
      variantId: variantId ?? this.variantId,
      sku: sku ?? this.sku,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    imageUrl,
    quantity,
    unitPrice,
    totalPrice,
    options,
    variantId,
    sku,
  ];
} 