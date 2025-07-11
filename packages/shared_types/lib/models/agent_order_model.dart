import 'package:equatable/equatable.dart';

/// Order status enumeration for agent app
enum OrderStatus {
  assigned,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
}

/// Order item model for agent app
class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'image_url': imageUrl,
    };
  }

  @override
  List<Object?> get props => [productId, productName, quantity, price, imageUrl];
}

/// Simplified address model for agent app
class DeliveryAddress extends Equatable {
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final double? latitude;
  final double? longitude;

  const DeliveryAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      landmark: json['landmark'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [street, city, state, pincode, landmark, latitude, longitude];
}

/// Agent order model - simplified for MVP
class AgentOrderModel extends Equatable {
  final String id;
  final String orderId;
  final String agentId;
  final String customerName;
  final String customerPhone;
  final DeliveryAddress deliveryAddress;
  final List<OrderItem> orderItems;
  final double totalAmount;
  final double deliveryFee;
  final OrderStatus status;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgentOrderModel({
    required this.id,
    required this.orderId,
    required this.agentId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.orderItems,
    required this.totalAmount,
    required this.deliveryFee,
    this.status = OrderStatus.assigned,
    required this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create AgentOrderModel from JSON
  factory AgentOrderModel.fromJson(Map<String, dynamic> json) {
    return AgentOrderModel(
      id: json['id'],
      orderId: json['order_id'],
      agentId: json['agent_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      deliveryAddress: DeliveryAddress.fromJson(json['delivery_address']),
      orderItems: (json['order_items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.assigned,
      ),
      assignedAt: DateTime.parse(json['assigned_at']),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Convert AgentOrderModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'agent_id': agentId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress.toJson(),
      'order_items': orderItems.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'delivery_fee': deliveryFee,
      'status': status.name,
      'assigned_at': assignedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  AgentOrderModel copyWith({
    String? id,
    String? orderId,
    String? agentId,
    String? customerName,
    String? customerPhone,
    DeliveryAddress? deliveryAddress,
    List<OrderItem>? orderItems,
    double? totalAmount,
    double? deliveryFee,
    OrderStatus? status,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentOrderModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      agentId: agentId ?? this.agentId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      orderItems: orderItems ?? this.orderItems,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        agentId,
        customerName,
        customerPhone,
        deliveryAddress,
        orderItems,
        totalAmount,
        deliveryFee,
        status,
        assignedAt,
        acceptedAt,
        pickedUpAt,
        deliveredAt,
        notes,
        createdAt,
        updatedAt,
      ];
}