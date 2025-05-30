import '../../domain/entities/order_item.dart';

/// Data model for OrderItem entity
class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required String id,
    required String productId,
    required String productName,
    String? imageUrl,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
    Map<String, dynamic>? options,
    String? variantId,
    String? sku,
  }) : super(
          id: id,
          productId: productId,
          productName: productName,
          imageUrl: imageUrl,
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: totalPrice,
          options: options,
          variantId: variantId,
          sku: sku,
        );

  /// Create an OrderItemModel from JSON data
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      imageUrl: json['image_url'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      options: json['options'] as Map<String, dynamic>?,
      variantId: json['variant_id'],
      sku: json['sku'],
    );
  }

  /// Convert OrderItemModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'image_url': imageUrl,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'options': options,
      'variant_id': variantId,
      'sku': sku,
    };
  }

  /// Create a copy of this OrderItemModel with the given fields replaced with the new values
  @override
  OrderItemModel copyWith({
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
    return OrderItemModel(
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
} 