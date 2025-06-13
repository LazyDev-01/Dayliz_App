import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/payment_method.dart';
import 'order_item_model.dart';
import 'address_model.dart';
import 'payment_method_model.dart';

/// Data model for Order entity
class OrderModel extends Order {
  // Order status constants
  static const String statusPending = 'pending';
  static const String statusProcessing = 'processing';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';
  static const String statusRefunded = 'refunded';

  const OrderModel({
    required String id,
    required String userId,
    String? orderNumber,
    required List<OrderItem> items,
    required double subtotal,
    required double tax,
    required double shipping,
    required double total,
    required String status,
    required DateTime createdAt,
    DateTime? updatedAt,
    required Address shippingAddress,
    Address? billingAddress,
    required PaymentMethod paymentMethod,
    String? trackingNumber,
    String? notes,
    String? couponCode,
    double? discount,
  }) : super(
          id: id,
          userId: userId,
          orderNumber: orderNumber,
          items: items,
          subtotal: subtotal,
          tax: tax,
          shipping: shipping,
          total: total,
          status: status,
          createdAt: createdAt,
          updatedAt: updatedAt,
          shippingAddress: shippingAddress,
          billingAddress: billingAddress,
          paymentMethod: paymentMethod,
          trackingNumber: trackingNumber,
          notes: notes,
          couponCode: couponCode,
          discount: discount,
        );

  /// Create an OrderModel from JSON data
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      orderNumber: json['order_number'],
      items: (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      shipping: (json['shipping'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      // Cast to Address since AddressModel extends Address
      shippingAddress: AddressModel.fromJson(json['shipping_address']) as Address,
      billingAddress: json['billing_address'] != null
          ? AddressModel.fromJson(json['billing_address']) as Address
          : null,
      paymentMethod: PaymentMethodModel.fromJson(json['payment_method']),
      trackingNumber: json['tracking_number'],
      notes: json['notes'],
      couponCode: json['coupon_code'],
      discount: json['discount'] != null
          ? (json['discount'] as num).toDouble()
          : null,
    );
  }

  /// Convert OrderModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'items': items
          .map((item) => (item as OrderItemModel).toJson())
          .toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'shipping_address': (shippingAddress as AddressModel).toJson(),
      'billing_address': billingAddress != null
          ? (billingAddress as AddressModel).toJson()
          : null,
      'payment_method': (paymentMethod as PaymentMethodModel).toJson(),
      'tracking_number': trackingNumber,
      'notes': notes,
      'coupon_code': couponCode,
      'discount': discount,
    };
  }

  /// Create a copy of this OrderModel with the given fields replaced with the new values
  @override
  OrderModel copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? shipping,
    double? total,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Address? shippingAddress,
    Address? billingAddress,
    PaymentMethod? paymentMethod,
    String? trackingNumber,
    String? notes,
    String? couponCode,
    double? discount,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      shipping: shipping ?? this.shipping,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress ?? this.billingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      notes: notes ?? this.notes,
      couponCode: couponCode ?? this.couponCode,
      discount: discount ?? this.discount,
    );
  }
}