import 'package:equatable/equatable.dart';

/// Order item model for agent orders
class OrderItem extends Equatable {
  final String productName;
  final double productPrice;
  final int quantity;
  final double totalPrice;
  final String? imageUrl;

  const OrderItem({
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.totalPrice,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['product_name'] ?? '',
      productPrice: double.tryParse(json['product_price']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'],
    );
  }

  @override
  List<Object?> get props => [productName, productPrice, quantity, totalPrice, imageUrl];
}

/// Delivery address model
class DeliveryAddress extends Equatable {
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String? landmark;

  const DeliveryAddress({
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.landmark,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      landmark: json['landmark'],
    );
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
    ].where((part) => part.isNotEmpty).toList();

    if (landmark != null && landmark!.isNotEmpty) {
      parts.add('Near $landmark');
    }

    return parts.join(', ');
  }

  @override
  List<Object?> get props => [addressLine1, addressLine2, city, state, postalCode, landmark];
}

/// Customer model
class Customer extends Equatable {
  final String name;
  final String phone;
  final String? email;

  const Customer({
    required this.name,
    required this.phone,
    this.email,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'] ?? 'Unknown Customer',
      phone: json['phone'] ?? '',
      email: json['email'],
    );
  }

  @override
  List<Object?> get props => [name, phone, email];
}

/// Agent order model for real database data
class AgentOrderModel extends Equatable {
  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final double deliveryFee;
  final String paymentMethod;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Customer customer;
  final DeliveryAddress deliveryAddress;
  final List<OrderItem> orderItems;

  const AgentOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.deliveryFee,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.customer,
    required this.deliveryAddress,
    required this.orderItems,
  });

  factory AgentOrderModel.fromDatabaseJson(Map<String, dynamic> json) {
    // Parse delivery address - handle both direct and foreign key formats
    final addressData = (json['addresses'] ?? json['addresses!orders_delivery_address_id_fkey']) as Map<String, dynamic>? ?? {};
    final deliveryAddress = DeliveryAddress.fromJson(addressData);

    // Parse customer data from delivery address (recipient info)
    final customer = Customer.fromJson({
      'name': addressData['recipient_name'] ?? 'Unknown Customer',
      'phone': addressData['phone_number'] ?? '',
      'email': null, // Email not needed for delivery
    });

    // Parse order items
    final itemsData = json['order_items'] as List<dynamic>? ?? [];
    final orderItems = itemsData.map((item) => OrderItem.fromJson(item)).toList();

    return AgentOrderModel(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      customer: customer,
      deliveryAddress: deliveryAddress,
      orderItems: orderItems,
    );
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Processing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'processing':
        return '#FF9800'; // Orange
      case 'out_for_delivery':
        return '#2196F3'; // Blue
      case 'delivered':
        return '#4CAF50'; // Green
      case 'cancelled':
        return '#F44336'; // Red
      default:
        return '#757575'; // Grey
    }
  }

  /// Get total items count
  int get totalItemsCount {
    return orderItems.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get items summary text
  String get itemsSummary {
    if (orderItems.isEmpty) return 'No items';
    if (orderItems.length == 1) {
      final item = orderItems.first;
      return '${item.productName} x${item.quantity}';
    }
    return '${orderItems.length} items (${totalItemsCount} total)';
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        totalAmount,
        deliveryFee,
        paymentMethod,
        paymentStatus,
        notes,
        createdAt,
        updatedAt,
        customer,
        deliveryAddress,
        orderItems,
      ];
}
