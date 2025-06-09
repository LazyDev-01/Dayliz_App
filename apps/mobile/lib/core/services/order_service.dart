import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/order.dart' as domain;
import '../../domain/entities/order_item.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/payment_method.dart';
import '../../data/models/order_model.dart';
import '../errors/exceptions.dart';

/// Service for handling order operations with Supabase
class OrderService {
  final SupabaseClient _supabase;

  OrderService({required SupabaseClient supabaseClient}) 
      : _supabase = supabaseClient;

  /// Create a new order with items
  Future<domain.Order> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double shipping,
    required double total,
    required String paymentMethod,
    required String deliveryAddressId,
    String? notes,
    String? couponCode,
    double? discount,
  }) async {
    try {
      debugPrint('OrderService: Creating order for user $userId');
      
      // Validate user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null || user.id != userId) {
        throw ServerException(message: 'User not authenticated or invalid user ID');
      }

      // Validate required data
      if (items.isEmpty) {
        throw ServerException(message: 'Order must contain at least one item');
      }

      if (total <= 0) {
        throw ServerException(message: 'Order total must be greater than 0');
      }

      // Prepare order data for database
      final orderData = {
        'user_id': userId,
        'total_amount': total,
        'subtotal': subtotal,
        'tax': tax,
        'shipping': shipping,
        'discount': discount ?? 0.0,
        'final_amount': total,
        'status': 'pending',
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        'delivery_address_id': deliveryAddressId,
        'notes': notes,
        'coupon_code': couponCode,
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('OrderService: Order data prepared: $orderData');

      // Create order using database function for transaction safety
      final response = await _supabase.rpc('create_order_with_items', params: {
        'order_data': orderData,
        'order_items': items,
      });

      if (response == null) {
        throw ServerException(message: 'Failed to create order - no response from database');
      }

      debugPrint('OrderService: Order created successfully: $response');

      // Convert response to Order entity
      return _mapDatabaseOrderToEntity(response);

    } catch (e) {
      debugPrint('OrderService: Error creating order: $e');
      if (e is PostgrestException) {
        throw ServerException(message: 'Database error: ${e.message}');
      } else if (e is ServerException) {
        rethrow;
      } else {
        throw ServerException(message: 'Failed to create order: $e');
      }
    }
  }

  /// Get order by ID
  Future<domain.Order> getOrderById(String orderId) async {
    try {
      debugPrint('OrderService: Getting order by ID: $orderId');

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(*),
            addresses!delivery_address_id(*),
            payment_methods!payment_method_id(*)
          ''')
          .eq('id', orderId)
          .single();

      debugPrint('OrderService: Order retrieved: $response');

      return _mapDatabaseOrderToEntity(response);

    } catch (e) {
      debugPrint('OrderService: Error getting order: $e');
      if (e is PostgrestException) {
        if (e.code == 'PGRST116') {
          throw NotFoundException(message: 'Order not found');
        }
        throw ServerException(message: 'Database error: ${e.message}');
      } else {
        throw ServerException(message: 'Failed to get order: $e');
      }
    }
  }

  /// Get all orders for a user
  Future<List<domain.Order>> getUserOrders(String userId) async {
    try {
      debugPrint('OrderService: Getting orders for user: $userId');

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(*),
            addresses!delivery_address_id(*),
            payment_methods!payment_method_id(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('OrderService: Retrieved ${response.length} orders');

      return response.map<domain.Order>((orderData) => 
          _mapDatabaseOrderToEntity(orderData)).toList();

    } catch (e) {
      debugPrint('OrderService: Error getting user orders: $e');
      if (e is PostgrestException) {
        throw ServerException(message: 'Database error: ${e.message}');
      } else {
        throw ServerException(message: 'Failed to get orders: $e');
      }
    }
  }

  /// Update order status
  Future<domain.Order> updateOrderStatus(String orderId, String status) async {
    try {
      debugPrint('OrderService: Updating order $orderId status to $status');

      final response = await _supabase
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select('''
            *,
            order_items(*),
            addresses!delivery_address_id(*),
            payment_methods!payment_method_id(*)
          ''')
          .single();

      debugPrint('OrderService: Order status updated: $response');

      return _mapDatabaseOrderToEntity(response);

    } catch (e) {
      debugPrint('OrderService: Error updating order status: $e');
      if (e is PostgrestException) {
        throw ServerException(message: 'Database error: ${e.message}');
      } else {
        throw ServerException(message: 'Failed to update order status: $e');
      }
    }
  }

  /// Cancel an order
  Future<domain.Order> cancelOrder(String orderId, {String? reason}) async {
    try {
      debugPrint('OrderService: Cancelling order $orderId');

      final response = await _supabase
          .from('orders')
          .update({
            'status': 'cancelled',
            'notes': reason != null ? 'Cancelled: $reason' : 'Cancelled by user',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select('''
            *,
            order_items(*),
            addresses!delivery_address_id(*),
            payment_methods!payment_method_id(*)
          ''')
          .single();

      debugPrint('OrderService: Order cancelled: $response');

      return _mapDatabaseOrderToEntity(response);

    } catch (e) {
      debugPrint('OrderService: Error cancelling order: $e');
      if (e is PostgrestException) {
        throw ServerException(message: 'Database error: ${e.message}');
      } else {
        throw ServerException(message: 'Failed to cancel order: $e');
      }
    }
  }

  /// Watch order status changes in real-time
  Stream<domain.Order> watchOrder(String orderId) {
    debugPrint('OrderService: Setting up real-time watch for order: $orderId');

    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((data) {
          if (data.isEmpty) {
            throw NotFoundException(message: 'Order not found');
          }
          return _mapDatabaseOrderToEntity(data.first);
        });
  }

  /// Map database order data to domain entity
  domain.Order _mapDatabaseOrderToEntity(Map<String, dynamic> data) {
    try {
      // Extract order items
      final orderItemsData = data['order_items'] as List<dynamic>? ?? [];
      final orderItems = orderItemsData.map<OrderItem>((item) {
        return OrderItem(
          id: item['id'] ?? '',
          productId: item['product_id'] ?? '',
          productName: item['product_name'] ?? '',
          quantity: (item['quantity'] ?? 0).toInt(),
          unitPrice: (item['product_price'] ?? 0.0).toDouble(),
          totalPrice: (item['total_price'] ?? 0.0).toDouble(),
          imageUrl: item['image_url'],
        );
      }).toList();

      // Extract address
      final addressData = data['addresses'] ?? {};
      final shippingAddress = Address(
        id: addressData['id'] ?? '',
        userId: addressData['user_id'] ?? '',
        addressLine1: addressData['address_line1'] ?? '',
        addressLine2: addressData['address_line2'],
        city: addressData['city'] ?? '',
        state: addressData['state'] ?? '',
        postalCode: addressData['postal_code'] ?? '',
        country: addressData['country'] ?? '',
        latitude: addressData['latitude']?.toDouble(),
        longitude: addressData['longitude']?.toDouble(),
        landmark: addressData['landmark'],
        addressType: addressData['label'] ?? 'Home',
        isDefault: addressData['is_default'] ?? false,
      );

      // Extract payment method
      final paymentData = data['payment_methods'] ?? {};
      final paymentMethod = PaymentMethod(
        id: paymentData['id'] ?? '',
        userId: paymentData['user_id'] ?? '',
        type: paymentData['type'] ?? data['payment_method'] ?? 'cod',
        name: paymentData['name'] ?? 'Cash on Delivery',
        isDefault: paymentData['is_default'] ?? false,
        details: paymentData['details'] ?? {},
      );

      return domain.Order(
        id: data['id'] ?? '',
        userId: data['user_id'] ?? '',
        items: orderItems,
        subtotal: (data['subtotal'] ?? 0.0).toDouble(),
        tax: (data['tax'] ?? 0.0).toDouble(),
        shipping: (data['shipping'] ?? 0.0).toDouble(),
        total: (data['final_amount'] ?? data['total_amount'] ?? 0.0).toDouble(),
        status: data['status'] ?? 'pending',
        createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        trackingNumber: data['tracking_number'],
        notes: data['notes'],
        couponCode: data['coupon_code'],
        discount: (data['discount'] ?? 0.0).toDouble(),
      );

    } catch (e) {
      debugPrint('OrderService: Error mapping order data: $e');
      throw ServerException(message: 'Failed to parse order data: $e');
    }
  }
}
