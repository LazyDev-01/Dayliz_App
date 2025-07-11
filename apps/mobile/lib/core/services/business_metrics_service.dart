import 'dart:async';
import 'package:flutter/foundation.dart';
import 'monitoring_service.dart';

/// Business Metrics Service for Dayliz App
/// 
/// Tracks critical business KPIs:
/// - Order conversion rates
/// - Payment success rates
/// - User engagement metrics
/// - Cart abandonment rates
/// - Delivery performance
/// - Revenue metrics
class BusinessMetricsService {
  static final BusinessMetricsService _instance = BusinessMetricsService._internal();
  factory BusinessMetricsService() => _instance;
  BusinessMetricsService._internal();

  final MonitoringService _monitoring = MonitoringService();
  
  // Session tracking
  DateTime? _sessionStart;
  String? _currentScreen;
  final Map<String, DateTime> _screenStartTimes = {};
  
  // Cart tracking
  DateTime? _cartCreatedAt;
  int _cartItemCount = 0;
  double _cartValue = 0.0;
  
  // Order funnel tracking
  final Map<String, DateTime> _funnelSteps = {};

  /// Initialize business metrics tracking
  Future<void> initialize() async {
    _sessionStart = DateTime.now();
    await _monitoring.logEvent('user_session_start', {
      'session_id': _generateSessionId(),
    });
  }

  /// Track app launch and initialization
  Future<void> trackAppLaunch({
    Duration? initializationTime,
    bool? isFirstLaunch,
    String? launchSource,
  }) async {
    await _monitoring.logEvent('app_launch', {
      'initialization_time_ms': initializationTime?.inMilliseconds,
      'is_first_launch': isFirstLaunch,
      'launch_source': launchSource,
      'session_id': _generateSessionId(),
    });
  }

  /// Track screen navigation and time spent
  Future<void> trackScreenView(String screenName, {String? previousScreen}) async {
    final now = DateTime.now();
    
    // Calculate time spent on previous screen
    if (_currentScreen != null && _screenStartTimes.containsKey(_currentScreen)) {
      final timeSpent = now.difference(_screenStartTimes[_currentScreen]!);
      await _monitoring.trackPerformanceMetric('screen_time', 
        duration: timeSpent,
        additionalData: {
          'screen_name': _currentScreen,
          'session_id': _generateSessionId(),
        }
      );
    }
    
    // Track new screen view
    _currentScreen = screenName;
    _screenStartTimes[screenName] = now;
    
    await _monitoring.trackScreenView(screenName);
    await _monitoring.logEvent('screen_view', {
      'screen_name': screenName,
      'previous_screen': previousScreen,
      'session_id': _generateSessionId(),
    });
  }

  /// Track user authentication events
  Future<void> trackAuthEvent(String eventType, {
    String? method,
    bool? success,
    String? errorCode,
    Duration? duration,
  }) async {
    await _monitoring.logEvent('auth_$eventType', {
      'method': method,
      'success': success,
      'error_code': errorCode,
      'duration_ms': duration?.inMilliseconds,
      'session_id': _generateSessionId(),
    });
  }

  /// Track search and discovery
  Future<void> trackSearchEvent(String query, {
    int? resultCount,
    String? category,
    bool? hasResults,
    Duration? searchTime,
  }) async {
    await _monitoring.logEvent('search_performed', {
      'query_length': query.length,
      'result_count': resultCount,
      'category': category,
      'has_results': hasResults,
      'search_time_ms': searchTime?.inMilliseconds,
      'session_id': _generateSessionId(),
    });
  }

  /// Track product interactions
  Future<void> trackProductEvent(String eventType, {
    String? productId,
    String? productName,
    String? category,
    double? price,
    int? quantity,
    String? source,
  }) async {
    await _monitoring.logEvent('product_$eventType', {
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'price': price,
      'quantity': quantity,
      'source': source,
      'currency': 'INR',
      'session_id': _generateSessionId(),
    });
  }

  /// Track cart events and funnel
  Future<void> trackCartEvent(String eventType, {
    String? productId,
    int? quantity,
    double? itemPrice,
    int? totalItems,
    double? cartValue,
  }) async {
    // Update cart state
    if (eventType == 'add_to_cart') {
      _cartCreatedAt ??= DateTime.now();
      _cartItemCount = totalItems ?? _cartItemCount + (quantity ?? 1);
      _cartValue = cartValue ?? _cartValue + (itemPrice ?? 0.0) * (quantity ?? 1);
    } else if (eventType == 'remove_from_cart') {
      _cartItemCount = totalItems ?? _cartItemCount - (quantity ?? 1);
      _cartValue = cartValue ?? _cartValue - (itemPrice ?? 0.0) * (quantity ?? 1);
    } else if (eventType == 'cart_cleared') {
      _cartItemCount = 0;
      _cartValue = 0.0;
      _cartCreatedAt = null;
    }

    await _monitoring.logEvent('cart_$eventType', {
      'product_id': productId,
      'quantity': quantity,
      'item_price': itemPrice,
      'total_items': _cartItemCount,
      'cart_value': _cartValue,
      'cart_age_minutes': _cartCreatedAt != null 
        ? DateTime.now().difference(_cartCreatedAt!).inMinutes 
        : null,
      'currency': 'INR',
      'session_id': _generateSessionId(),
    });
  }

  /// Track checkout funnel
  Future<void> trackCheckoutStep(String step, {
    String? orderId,
    double? orderValue,
    int? itemCount,
    String? paymentMethod,
    String? deliveryMethod,
    Map<String, dynamic>? additionalData,
  }) async {
    _funnelSteps[step] = DateTime.now();
    
    // Calculate funnel progression time
    Duration? stepDuration;
    if (step == 'checkout_started' && _cartCreatedAt != null) {
      stepDuration = DateTime.now().difference(_cartCreatedAt!);
    } else if (_funnelSteps.containsKey('checkout_started')) {
      stepDuration = DateTime.now().difference(_funnelSteps['checkout_started']!);
    }

    await _monitoring.logEvent('checkout_$step', {
      'order_id': orderId,
      'order_value': orderValue,
      'item_count': itemCount,
      'payment_method': paymentMethod,
      'delivery_method': deliveryMethod,
      'step_duration_ms': stepDuration?.inMilliseconds,
      'cart_age_minutes': _cartCreatedAt != null 
        ? DateTime.now().difference(_cartCreatedAt!).inMinutes 
        : null,
      'currency': 'INR',
      'session_id': _generateSessionId(),
      ...?additionalData,
    });
  }

  /// Track order lifecycle
  Future<void> trackOrderLifecycle(String stage, {
    required String orderId,
    double? orderValue,
    String? paymentMethod,
    String? deliveryMethod,
    int? itemCount,
    Duration? processingTime,
    String? status,
    String? errorCode,
  }) async {
    await _monitoring.trackOrderEvent(stage, 
      orderId: orderId,
      orderValue: orderValue,
      paymentMethod: paymentMethod,
      itemCount: itemCount,
      additionalData: {
        'delivery_method': deliveryMethod,
        'processing_time_ms': processingTime?.inMilliseconds,
        'status': status,
        'error_code': errorCode,
        'session_id': _generateSessionId(),
      }
    );

    // Track order funnel completion
    if (stage == 'completed') {
      await _trackOrderFunnelCompletion(orderId, orderValue);
    }
  }

  /// Track payment events with detailed metrics
  Future<void> trackPaymentLifecycle(String stage, {
    required String paymentId,
    String? orderId,
    double? amount,
    String? paymentMethod,
    String? status,
    String? errorCode,
    Duration? processingTime,
  }) async {
    await _monitoring.trackPaymentEvent(stage,
      paymentId: paymentId,
      orderId: orderId,
      amount: amount,
      paymentMethod: paymentMethod,
      status: status,
      errorCode: errorCode,
      additionalData: {
        'processing_time_ms': processingTime?.inMilliseconds,
        'session_id': _generateSessionId(),
      }
    );
  }

  /// Track delivery and fulfillment
  Future<void> trackDeliveryEvent(String eventType, {
    String? orderId,
    String? deliveryId,
    String? agentId,
    Duration? estimatedTime,
    Duration? actualTime,
    String? status,
    double? rating,
  }) async {
    await _monitoring.logEvent('delivery_$eventType', {
      'order_id': orderId,
      'delivery_id': deliveryId,
      'agent_id': agentId,
      'estimated_time_minutes': estimatedTime?.inMinutes,
      'actual_time_minutes': actualTime?.inMinutes,
      'status': status,
      'rating': rating,
      'session_id': _generateSessionId(),
    });
  }

  /// Track user engagement metrics
  Future<void> trackEngagementEvent(String eventType, {
    String? feature,
    Duration? duration,
    int? interactionCount,
    String? outcome,
  }) async {
    await _monitoring.logEvent('engagement_$eventType', {
      'feature': feature,
      'duration_ms': duration?.inMilliseconds,
      'interaction_count': interactionCount,
      'outcome': outcome,
      'session_id': _generateSessionId(),
    });
  }

  /// Track app performance metrics
  Future<void> trackPerformanceEvent(String metricType, {
    Duration? loadTime,
    Duration? responseTime,
    String? endpoint,
    bool? success,
    String? errorType,
  }) async {
    await _monitoring.trackPerformanceMetric(metricType,
      duration: loadTime ?? responseTime,
      additionalData: {
        'endpoint': endpoint,
        'success': success,
        'error_type': errorType,
        'session_id': _generateSessionId(),
      }
    );
  }

  /// Track error events with context
  Future<void> trackErrorEvent(String errorType, {
    String? errorMessage,
    String? stackTrace,
    String? screen,
    String? action,
    Map<String, dynamic>? context,
  }) async {
    await _monitoring.logEvent('error_$errorType', {
      'error_message': errorMessage,
      'screen': screen,
      'action': action,
      'session_id': _generateSessionId(),
      ...?context,
    });
  }

  /// Track session end
  Future<void> trackSessionEnd() async {
    if (_sessionStart != null) {
      final sessionDuration = DateTime.now().difference(_sessionStart!);
      
      await _monitoring.logEvent('user_session_end', {
        'session_duration_ms': sessionDuration.inMilliseconds,
        'session_id': _generateSessionId(),
        'screens_viewed': _screenStartTimes.length,
        'cart_items': _cartItemCount,
        'cart_value': _cartValue,
      });
    }
  }

  /// Private helper methods

  String _generateSessionId() {
    return '${_sessionStart?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _trackOrderFunnelCompletion(String orderId, double? orderValue) async {
    final now = DateTime.now();
    
    // Calculate funnel conversion times
    Duration? cartToCheckout;
    Duration? checkoutToPayment;
    Duration? paymentToCompletion;
    Duration? totalFunnelTime;

    if (_cartCreatedAt != null && _funnelSteps.containsKey('checkout_started')) {
      cartToCheckout = _funnelSteps['checkout_started']!.difference(_cartCreatedAt!);
    }
    
    if (_funnelSteps.containsKey('checkout_started') && _funnelSteps.containsKey('payment_started')) {
      checkoutToPayment = _funnelSteps['payment_started']!.difference(_funnelSteps['checkout_started']!);
    }
    
    if (_funnelSteps.containsKey('payment_started')) {
      paymentToCompletion = now.difference(_funnelSteps['payment_started']!);
    }
    
    if (_cartCreatedAt != null) {
      totalFunnelTime = now.difference(_cartCreatedAt!);
    }

    await _monitoring.logEvent('order_funnel_completed', {
      'order_id': orderId,
      'order_value': orderValue,
      'cart_to_checkout_ms': cartToCheckout?.inMilliseconds,
      'checkout_to_payment_ms': checkoutToPayment?.inMilliseconds,
      'payment_to_completion_ms': paymentToCompletion?.inMilliseconds,
      'total_funnel_time_ms': totalFunnelTime?.inMilliseconds,
      'currency': 'INR',
      'session_id': _generateSessionId(),
    });

    // Reset funnel tracking
    _funnelSteps.clear();
    _cartCreatedAt = null;
    _cartItemCount = 0;
    _cartValue = 0.0;
  }
}
