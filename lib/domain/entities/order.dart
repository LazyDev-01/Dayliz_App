import 'package:equatable/equatable.dart';
import 'address.dart';
import 'order_item.dart';
import 'payment_method.dart';

/// Represents an order in the domain layer
class Order extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Address shippingAddress;
  final Address? billingAddress;
  final PaymentMethod paymentMethod;
  final String? trackingNumber;
  final String? notes;
  final String? couponCode;
  final double? discount;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.shippingAddress,
    this.billingAddress,
    required this.paymentMethod,
    this.trackingNumber,
    this.notes,
    this.couponCode,
    this.discount,
  });

  /// Order statuses
  static const String statusPending = 'pending';
  static const String statusProcessing = 'processing';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';
  static const String statusRefunded = 'refunded';

  /// Returns true if the order is still active (not cancelled or refunded)
  bool get isActive => status != statusCancelled && status != statusRefunded;

  /// Returns true if the order can be cancelled
  bool get canBeCancelled => status == statusPending || status == statusProcessing;

  /// Returns true if the order has been shipped
  bool get isShipped => status == statusShipped || status == statusDelivered;

  /// Returns the total number of items in the order
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Returns a copy of this Order with the given fields replaced with the new values
  Order copyWith({
    String? id,
    String? userId,
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
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        subtotal,
        tax,
        shipping,
        total,
        status,
        createdAt,
        updatedAt,
        shippingAddress,
        billingAddress,
        paymentMethod,
        trackingNumber,
        notes,
        couponCode,
        discount,
      ];
} 