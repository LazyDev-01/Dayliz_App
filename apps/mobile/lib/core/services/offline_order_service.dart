import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for handling offline order queuing and synchronization
class OfflineOrderService {
  static const String _queueKey = 'offline_order_queue';
  static const String _failedOrdersKey = 'failed_orders';

  OfflineOrderService();

  /// Queue order for offline processing
  Future<String> queueOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double total,
    required double subtotal,
    required double tax,
    required double shipping,
    required String deliveryAddressId,
    required String paymentMethod,
    String? notes,
    String? couponCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queuedOrders = await _getQueuedOrders();
      
      // Generate temporary order ID
      final tempOrderId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      final orderData = {
        'temp_id': tempOrderId,
        'user_id': userId,
        'items': items,
        'total': total,
        'subtotal': subtotal,
        'tax': tax,
        'shipping': shipping,
        'delivery_address_id': deliveryAddressId,
        'payment_method': paymentMethod,
        'notes': notes,
        'coupon_code': couponCode,
        'queued_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      };
      
      queuedOrders.add(orderData);
      
      await prefs.setString(_queueKey, jsonEncode(queuedOrders));
      
      debugPrint('OfflineOrderService: Order queued with temp ID: $tempOrderId');
      
      // Order will be processed when connection is restored
      debugPrint('OfflineOrderService: Order queued, will sync when online');
      
      return tempOrderId;
    } catch (e) {
      debugPrint('OfflineOrderService: Failed to queue order: $e');
      rethrow;
    }
  }

  /// Get all queued orders
  Future<List<Map<String, dynamic>>> _getQueuedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson == null) return [];
      
      final List<dynamic> queueList = jsonDecode(queueJson);
      return queueList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('OfflineOrderService: Failed to get queued orders: $e');
      return [];
    }
  }

  /// Process all queued orders (simplified version)
  Future<void> processQueuedOrders() async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('OfflineOrderService: No internet connection, skipping queue processing');
        return;
      }

      final queuedOrders = await _getQueuedOrders();
      if (queuedOrders.isEmpty) return;

      debugPrint('OfflineOrderService: Found ${queuedOrders.length} queued orders. Manual processing required.');

      // For now, just log the queued orders
      // In a full implementation, this would integrate with the order service
      // to process the queued orders when connectivity is restored

    } catch (e) {
      debugPrint('OfflineOrderService: Error checking queue: $e');
    }
  }

  /// Get failed orders
  Future<List<Map<String, dynamic>>> _getFailedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedJson = prefs.getString(_failedOrdersKey);
      
      if (failedJson == null) return [];
      
      final List<dynamic> failedList = jsonDecode(failedJson);
      return failedList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('OfflineOrderService: Failed to get failed orders: $e');
      return [];
    }
  }

  /// Get queue status for UI
  Future<Map<String, dynamic>> getQueueStatus() async {
    final queuedOrders = await _getQueuedOrders();
    final failedOrders = await _getFailedOrders();
    
    return {
      'queued_count': queuedOrders.length,
      'failed_count': failedOrders.length,
      'total_pending': queuedOrders.length + failedOrders.length,
      'last_sync': queuedOrders.isNotEmpty 
          ? queuedOrders.last['last_retry'] ?? queuedOrders.last['queued_at']
          : null,
    };
  }

  /// Manually trigger queue processing
  Future<void> syncOrders() async {
    debugPrint('OfflineOrderService: Manual sync triggered');
    await processQueuedOrders();
  }

  /// Clear failed orders (after user acknowledgment)
  Future<void> clearFailedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failedOrdersKey);
    debugPrint('OfflineOrderService: Failed orders cleared');
  }

  /// Retry specific failed order
  Future<bool> retryFailedOrder(String tempOrderId) async {
    try {
      final failedOrders = await _getFailedOrders();
      final orderIndex = failedOrders.indexWhere((order) => order['temp_id'] == tempOrderId);
      
      if (orderIndex == -1) {
        debugPrint('OfflineOrderService: Failed order not found: $tempOrderId');
        return false;
      }

      final orderData = failedOrders[orderIndex];
      
      // Move back to queue for retry
      final queuedOrders = await _getQueuedOrders();
      orderData['retry_count'] = 0; // Reset retry count
      queuedOrders.add(orderData);
      
      // Remove from failed orders
      failedOrders.removeAt(orderIndex);
      
      // Update storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueKey, jsonEncode(queuedOrders));
      await prefs.setString(_failedOrdersKey, jsonEncode(failedOrders));
      
      // Process queue
      await processQueuedOrders();
      
      debugPrint('OfflineOrderService: Retrying failed order: $tempOrderId');
      return true;
    } catch (e) {
      debugPrint('OfflineOrderService: Failed to retry order: $e');
      return false;
    }
  }

  /// Initialize offline service and start background sync
  Future<void> initialize() async {
    debugPrint('OfflineOrderService: Initializing offline order service');
    
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        debugPrint('OfflineOrderService: Internet connection restored, processing queue');
        processQueuedOrders();
      }
    });

    // Process any existing queued orders
    await processQueuedOrders();
  }
}
