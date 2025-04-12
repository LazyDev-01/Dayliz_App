import 'package:equatable/equatable.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/models/payment_method.dart';
import 'package:dayliz_app/models/product.dart';

// Enums for order status
enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
  returned;
  
  String get value {
    switch (this) {
      case OrderStatus.pending: return 'pending';
      case OrderStatus.processing: return 'processing';
      case OrderStatus.shipped: return 'shipped';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.cancelled: return 'cancelled';
      case OrderStatus.returned: return 'returned';
    }
  }
  
  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return OrderStatus.pending;
      case 'processing': return OrderStatus.processing;
      case 'shipped': return OrderStatus.shipped;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      case 'returned': return OrderStatus.returned;
      default: return OrderStatus.pending;
    }
  }
}

// Enums for payment status
enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;
  
  String get value {
    switch (this) {
      case PaymentStatus.pending: return 'pending';
      case PaymentStatus.completed: return 'completed';
      case PaymentStatus.failed: return 'failed';
      case PaymentStatus.refunded: return 'refunded';
    }
  }
  
  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return PaymentStatus.pending;
      case 'completed': return PaymentStatus.completed;
      case 'failed': return PaymentStatus.failed;
      case 'refunded': return PaymentStatus.refunded;
      default: return PaymentStatus.pending;
    }
  }
}

// Enums for payment method
enum PaymentMethod {
  creditCard,
  debitCard,
  upi,
  netBanking,
  wallet,
  cashOnDelivery;
  
  String get value {
    switch (this) {
      case PaymentMethod.creditCard: return 'credit_card';
      case PaymentMethod.debitCard: return 'debit_card';
      case PaymentMethod.upi: return 'upi';
      case PaymentMethod.netBanking: return 'net_banking';
      case PaymentMethod.wallet: return 'wallet';
      case PaymentMethod.cashOnDelivery: return 'cash_on_delivery';
    }
  }
  
  static PaymentMethod fromString(String method) {
    switch (method.toLowerCase()) {
      case 'credit_card': return PaymentMethod.creditCard;
      case 'debit_card': return PaymentMethod.debitCard;
      case 'upi': return PaymentMethod.upi;
      case 'net_banking': return PaymentMethod.netBanking;
      case 'wallet': return PaymentMethod.wallet;
      case 'cash_on_delivery': return PaymentMethod.cashOnDelivery;
      default: return PaymentMethod.cashOnDelivery;
    }
  }
}

// Simple Address class for orders - renamed to OrderAddress to avoid conflicts
class OrderAddress {
  final String? id;
  final String fullName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String phoneNumber;
  final bool isDefault;
  
  const OrderAddress({
    this.id,
    required this.fullName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phoneNumber,
    this.isDefault = false,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'phoneNumber': phoneNumber,
      'isDefault': isDefault,
    };
  }
  
  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      id: json['id'],
      fullName: json['fullName'],
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      phoneNumber: json['phoneNumber'],
      isDefault: json['isDefault'] ?? false,
    );
  }
  
  // Convert from Address model to OrderAddress
  factory OrderAddress.fromAddress(Address address) {
    return OrderAddress(
      id: address.id,
      fullName: address.name,
      addressLine1: address.addressLine1,
      addressLine2: address.addressLine2,
      city: address.city,
      state: address.state,
      postalCode: address.postalCode,
      country: address.country,
      phoneNumber: address.phoneNumber,
      isDefault: address.isDefault,
    );
  }
}

class OrderItem extends Equatable {
  final String? id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final double? discountAmount;
  final Map<String, dynamic>? attributes; // size, color, etc.
  
  const OrderItem({
    this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.discountAmount,
    this.attributes,
  });

  double get total => price * quantity - (discountAmount ?? 0);

  OrderItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    double? discountAmount,
    Map<String, dynamic>? attributes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
      attributes: attributes ?? this.attributes,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      discountAmount: json['discount_amount']?.toDouble(),
      attributes: json['attributes'],
    );
  }

  factory OrderItem.fromProduct(Product product, int quantity) {
    return OrderItem(
      id: null,
      productId: product.id,
      name: product.name,
      imageUrl: product.imageUrl,
      price: product.price,
      quantity: quantity,
      discountAmount: product.discountedPrice,
      attributes: product.attributes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'quantity': quantity,
      'discount_amount': discountAmount,
      'attributes': attributes,
    };
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    name,
    imageUrl,
    price,
    quantity,
    discountAmount,
    attributes,
  ];
}

class Order extends Equatable {
  final String? id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderAddress? shippingAddress;
  final OrderAddress? billingAddress;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? trackingNumber;
  final String? cancellationReason;
  final double? refundAmount;
  
  Order({
    this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.shippingAddress,
    this.billingAddress,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.trackingNumber,
    this.cancellationReason,
    this.refundAmount,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    OrderAddress? shippingAddress,
    OrderAddress? billingAddress,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? trackingNumber,
    String? cancellationReason,
    double? refundAmount,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress ?? this.billingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      refundAmount: refundAmount ?? this.refundAmount,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      shippingAddress: json['shipping_address'] != null
          ? OrderAddress.fromJson(json['shipping_address'])
          : null,
      billingAddress: json['billing_address'] != null
          ? OrderAddress.fromJson(json['billing_address'])
          : null,
      paymentMethod: PaymentMethod.fromString(json['payment_method'] ?? 'cash_on_delivery'),
      paymentStatus: PaymentStatus.fromString(json['payment_status'] ?? 'pending'),
      trackingNumber: json['tracking_number'],
      cancellationReason: json['cancellation_reason'],
      refundAmount: json['refund_amount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'shipping_address': shippingAddress?.toJson(),
      'billing_address': billingAddress?.toJson(),
      'payment_method': paymentMethod.value,
      'payment_status': paymentStatus.value,
      'tracking_number': trackingNumber,
      'cancellation_reason': cancellationReason,
      'refund_amount': refundAmount,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    items,
    totalAmount,
    status,
    createdAt,
    updatedAt,
    shippingAddress,
    billingAddress,
    paymentMethod,
    paymentStatus,
    trackingNumber,
    cancellationReason,
    refundAmount,
  ];
} 