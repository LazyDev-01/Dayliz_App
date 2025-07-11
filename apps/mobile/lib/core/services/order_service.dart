import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/order.dart' as domain;
import '../../domain/entities/order_item.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/payment_method.dart';
import '../../data/models/order_model.dart';
import '../errors/exceptions.dart';
import 'network_service.dart';
import 'offline_order_service.dart';

/// Service for handling order operations with Supabase
class OrderService {
  final SupabaseClient _supabase;
  late final OfflineOrderService _offlineOrderService;

  OrderService({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient {
    _offlineOrderService = OfflineOrderService();
  }

  /// Create order with smart retry mechanism and offline support
  Future<Map<String, dynamic>?> _createOrderWithRetry(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> items,
  ) async {
    // Check network connectivity first
    final hasInternet = await NetworkService.hasInternetConnection();

    if (!hasInternet) {
      // Queue order for offline processing
      debugPrint('OrderService: No internet, queuing order offline');
      final tempOrderId = await _offlineOrderService.queueOrder(
        userId: orderData['user_id'],
        items: items,
        total: orderData['total_amount'],
        subtotal: orderData['subtotal'] ?? 0,
        tax: orderData['tax'] ?? 0,
        shipping: orderData['shipping'] ?? 0,
        deliveryAddressId: orderData['delivery_address_id'],
        paymentMethod: orderData['payment_method'],
        notes: orderData['notes'],
        couponCode: orderData['coupon_code'],
      );

      // Return offline order response
      return {
        'success': true,
        'id': tempOrderId,
        'order_number': 'OFFLINE-$tempOrderId',
        'status': 'queued',
        'message': 'Order queued for processing when connection is restored',
        'offline': true,
      };
    }

    Exception? lastException;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('OrderService: Order creation attempt $attempt/3');

        // Create order using original function
        final response = await _supabase.rpc('create_order_with_items_hierarchical', params: {
          'order_data': orderData,
          'order_items': items,
          'user_lat': null, // Remove GPS request
          'user_lng': null, // Remove GPS request
        });

        // If order creation successful, deduct stock immediately
        if (response != null && response['success'] == true) {
          try {
            debugPrint('OrderService: Attempting stock deduction for order ${response['order_number']}');
            debugPrint('OrderService: Deducting stock for ${items.length} items');

            int successCount = 0;
            int failCount = 0;

            // Deduct stock for each item individually (more reliable)
            for (final item in items) {
              try {
                final stockResult = await _supabase.rpc('deduct_single_product_stock', params: {
                  'product_id_param': item['product_id'],
                  'quantity_param': item['quantity'],
                  'product_name_param': item['product_name'],
                });

                if (stockResult != null && stockResult['success'] == true) {
                  successCount++;
                  debugPrint('OrderService: ✅ ${stockResult['message']}');
                } else {
                  failCount++;
                  debugPrint('OrderService: ❌ ${stockResult?['error'] ?? 'Unknown error'}');
                }
              } catch (itemError) {
                failCount++;
                debugPrint('OrderService: ❌ Stock deduction failed for ${item['product_name']}: $itemError');
              }
            }

            debugPrint('OrderService: Stock deduction complete - Success: $successCount, Failed: $failCount');

          } catch (stockError) {
            debugPrint('OrderService: ❌ Stock deduction exception: $stockError');
            // Continue - order is created, stock deduction can be handled manually
          }
        }

        // If successful, return immediately
        if (response != null) {
          debugPrint('OrderService: Order creation successful on attempt $attempt');
          return response;
        }

      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        final errorType = NetworkService.classifyError(e);

        debugPrint('OrderService: Attempt $attempt failed: $e (Type: $errorType)');

        // Get retry strategy based on error type
        final retryStrategy = NetworkService.getRetryStrategy(errorType);

        if (!retryStrategy.shouldRetry || attempt >= retryStrategy.maxAttempts) {
          break;
        }

        // Wait before retry
        if (attempt < 3) {
          await Future.delayed(retryStrategy.delayBetweenAttempts);
        }
      }
    }

    // All attempts failed - check if we should queue offline
    if (lastException != null && NetworkService.shouldUseOfflineMode(lastException)) {
      debugPrint('OrderService: Network error detected, queuing order offline');
      final tempOrderId = await _offlineOrderService.queueOrder(
        userId: orderData['user_id'],
        items: items,
        total: orderData['total_amount'],
        subtotal: orderData['subtotal'] ?? 0,
        tax: orderData['tax'] ?? 0,
        shipping: orderData['shipping'] ?? 0,
        deliveryAddressId: orderData['delivery_address_id'],
        paymentMethod: orderData['payment_method'],
        notes: orderData['notes'],
        couponCode: orderData['coupon_code'],
      );

      return {
        'success': true,
        'id': tempOrderId,
        'order_number': 'OFFLINE-$tempOrderId',
        'status': 'queued',
        'message': 'Order queued due to network issues. Will be processed when connection is restored.',
        'offline': true,
      };
    }

    // Throw the last exception
    if (lastException != null) {
      throw lastException;
    }

    return null;
  }

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
        'status': 'processing',
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        'delivery_address_id': deliveryAddressId,
        'notes': notes,
        'coupon_code': couponCode,
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('OrderService: Creating order for ${items.length} items, total: ₹$total');

      // Use delivery address for zone detection instead of GPS
      // TODO: Extract coordinates from selected delivery address when address geocoding is implemented
      debugPrint('OrderService: Using delivery address for zone detection');

      // Create order using hierarchical database function with retry mechanism
      final response = await _createOrderWithRetry(orderData, items);

      if (response == null) {
        throw ServerException(message: 'Failed to create order - no response from database');
      }

      debugPrint('OrderService: Order creation ${response['success'] == true ? 'successful' : 'failed'}');

      // Check if order creation was successful
      final isSuccess = response['success'] as bool? ?? false;

      if (!isSuccess) {
        // Handle different types of validation errors
        final error = response['error'] as String?;
        final message = response['message'] as String?;
        final stockIssues = response['stock_issues'] as List<dynamic>?;

        if (error == 'INSUFFICIENT_STOCK' && stockIssues != null) {
          // Create detailed error message for stock issues
          final issueMessages = stockIssues.map((issue) {
            final productName = issue['product_name'] ?? 'Unknown Product';
            final requested = issue['requested_quantity'] ?? 0;
            final available = issue['available_stock'] ?? 0;
            return '$productName: Requested $requested, Available $available';
          }).join('\n');

          throw ServerException(
            message: 'Insufficient stock for some items:\n$issueMessages'
          );
        } else if (error?.startsWith('INVALID_PAYMENT') == true) {
          throw ServerException(
            message: message ?? 'Invalid payment method selected'
          );
        } else if (error?.contains('ORDER_AMOUNT') == true) {
          throw ServerException(
            message: message ?? 'Invalid order amount'
          );
        } else if (error?.startsWith('COD_LIMIT') == true) {
          throw ServerException(
            message: message ?? 'COD order limit exceeded'
          );
        } else if (error == 'TRANSACTION_FAILED') {
          throw ServerException(
            message: 'Order processing failed. Please try again.'
          );
        } else if (error == 'ORDER_NUMBER_CONFLICT') {
          throw ServerException(
            message: 'Order processing conflict. Please try again.'
          );
        } else if (error == 'ORDER_CREATION_TIMEOUT') {
          throw ServerException(
            message: 'Order processing timed out. Please try again.'
          );
        } else {
          throw ServerException(message: message ?? 'Failed to create order');
        }
      }

      // Extract order ID from successful response
      final orderId = response['id'] as String;

      // Fetch the complete order data with items and address
      final completeOrderResponse = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(*),
            addresses!delivery_address_id(*),
            payment_methods!payment_method_id(*)
          ''')
          .eq('id', orderId)
          .single();

      debugPrint('OrderService: Order ${completeOrderResponse['order_number']} retrieved successfully');

      // Convert response to Order entity
      return _mapDatabaseOrderToEntity(completeOrderResponse);

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

      // First restore stock for the cancelled order
      try {
        // Get order items to restore stock
        final orderItemsResponse = await _supabase
            .from('order_items')
            .select('product_id, quantity, product_name')
            .eq('order_id', orderId);

        if (orderItemsResponse.isNotEmpty) {
          debugPrint('OrderService: Restoring stock for ${orderItemsResponse.length} items');

          int successCount = 0;
          int failCount = 0;

          for (final item in orderItemsResponse) {
            try {
              final stockResult = await _supabase.rpc('restore_single_product_stock', params: {
                'product_id_param': item['product_id'],
                'quantity_param': item['quantity'],
                'product_name_param': item['product_name'],
              });

              if (stockResult != null && stockResult['success'] == true) {
                successCount++;
                debugPrint('OrderService: ✅ ${stockResult['message']}');
              } else {
                failCount++;
                debugPrint('OrderService: ❌ ${stockResult?['error'] ?? 'Unknown error'}');
              }
            } catch (itemError) {
              failCount++;
              debugPrint('OrderService: ❌ Stock restoration failed for ${item['product_name']}: $itemError');
            }
          }

          debugPrint('OrderService: Stock restoration complete - Success: $successCount, Failed: $failCount');
        }
      } catch (stockError) {
        debugPrint('OrderService: ❌ Stock restoration exception: $stockError');
        // Continue with cancellation even if stock restoration fails
      }

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
        addressLine2: addressData['address_line2'] ?? '', // Provide default empty string
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
        orderNumber: data['order_number'], // Can be null, handled by domain entity
        items: orderItems,
        subtotal: (data['subtotal'] ?? 0.0).toDouble(),
        tax: (data['tax'] ?? 0.0).toDouble(),
        shipping: (data['shipping'] ?? 0.0).toDouble(),
        total: (data['final_amount'] ?? data['total_amount'] ?? 0.0).toDouble(),
        status: data['status'] ?? 'processing',
        createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()).toLocal(), // Convert to local time
        updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']).toLocal() : null, // Convert to local time
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
