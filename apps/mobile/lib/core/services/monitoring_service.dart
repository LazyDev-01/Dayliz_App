import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Comprehensive Monitoring Service for Dayliz App
/// 
/// Features:
/// - Firebase Crashlytics integration
/// - Performance monitoring
/// - Custom business metrics tracking
/// - User experience analytics
/// - Production-ready error handling
class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  late FirebaseCrashlytics _crashlytics;
  late FirebasePerformance _performance;
  late FirebaseAnalytics _analytics;
  
  bool _isInitialized = false;
  String? _userId;
  Map<String, dynamic> _userProperties = {};

  /// Initialize monitoring service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase services
      _crashlytics = FirebaseCrashlytics.instance;
      _performance = FirebasePerformance.instance;
      _analytics = FirebaseAnalytics.instance;

      // Configure Crashlytics
      await _configureCrashlytics();
      
      // Set up performance monitoring
      await _configurePerformanceMonitoring();
      
      // Configure analytics
      await _configureAnalytics();
      
      // Set device and app information
      await _setDeviceInfo();
      
      _isInitialized = true;
      
      // Log successful initialization
      await logEvent('monitoring_service_initialized', {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
      });
      
      debugPrint('✅ MonitoringService initialized successfully');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize MonitoringService: $e');
      // Don't rethrow - monitoring should not break the app
    }
  }

  /// Configure Firebase Crashlytics
  Future<void> _configureCrashlytics() async {
    // Enable crashlytics collection in release mode
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    
    // Set up automatic crash reporting
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordFlutterFatalError(errorDetails);
    };
    
    // Catch errors outside of Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Configure Firebase Performance Monitoring
  Future<void> _configurePerformanceMonitoring() async {
    // Enable performance monitoring
    await _performance.setPerformanceCollectionEnabled(!kDebugMode);
  }

  /// Configure Firebase Analytics
  Future<void> _configureAnalytics() async {
    // Enable analytics collection
    await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
  }

  /// Set device and app information for better crash reporting
  Future<void> _setDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Set app information
      await _crashlytics.setCustomKey('app_version', packageInfo.version);
      await _crashlytics.setCustomKey('build_number', packageInfo.buildNumber);
      await _crashlytics.setCustomKey('package_name', packageInfo.packageName);
      
      // Set device information
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        await _crashlytics.setCustomKey('device_model', androidInfo.model);
        await _crashlytics.setCustomKey('android_version', androidInfo.version.release);
        await _crashlytics.setCustomKey('manufacturer', androidInfo.manufacturer);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        await _crashlytics.setCustomKey('device_model', iosInfo.model);
        await _crashlytics.setCustomKey('ios_version', iosInfo.systemVersion);
        await _crashlytics.setCustomKey('device_name', iosInfo.name);
      }
      
    } catch (e) {
      debugPrint('Failed to set device info: $e');
    }
  }

  /// Set user identifier for crash reporting
  Future<void> setUserId(String userId) async {
    if (!_isInitialized) return;
    
    try {
      _userId = userId;
      await _crashlytics.setUserIdentifier(userId);
      await _analytics.setUserId(id: userId);
      
      debugPrint('✅ User ID set for monitoring: $userId');
    } catch (e) {
      debugPrint('Failed to set user ID: $e');
    }
  }

  /// Set user properties for better analytics
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_isInitialized) return;
    
    try {
      _userProperties.addAll(properties);
      
      // Set properties in Crashlytics
      for (final entry in properties.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
      
      // Set properties in Analytics
      for (final entry in properties.entries) {
        await _analytics.setUserProperty(
          name: entry.key,
          value: entry.value.toString(),
        );
      }
      
    } catch (e) {
      debugPrint('Failed to set user properties: $e');
    }
  }

  /// Log custom events for business metrics
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    if (!_isInitialized) return;
    
    try {
      // Add common parameters
      final enrichedParameters = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': _userId ?? 'anonymous',
        'platform': Platform.operatingSystem,
        ...?parameters,
      };
      
      // Log to Firebase Analytics
      // Convert dynamic values to Object for Firebase Analytics
      final Map<String, Object> analyticsParameters = {};
      enrichedParameters.forEach((key, value) {
        if (value != null) {
          analyticsParameters[key] = value.toString();
        }
      });

      await _analytics.logEvent(
        name: eventName,
        parameters: analyticsParameters,
      );
      
      // Log to Crashlytics as breadcrumb
      await _crashlytics.log('Event: $eventName - ${enrichedParameters.toString()}');
      
    } catch (e) {
      debugPrint('Failed to log event $eventName: $e');
    }
  }

  /// Record non-fatal errors
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalData,
    bool fatal = false,
  }) async {
    if (!_isInitialized) return;
    
    try {
      // Add context information
      final context = <String, dynamic>{
        'user_id': _userId ?? 'anonymous',
        'timestamp': DateTime.now().toIso8601String(),
        'reason': reason ?? 'Unknown error',
        ...?additionalData,
      };
      
      // Set context in Crashlytics
      for (final entry in context.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
      
      // Record the error
      await _crashlytics.recordError(
        exception,
        stackTrace,
        fatal: fatal,
        information: [
          DiagnosticsProperty('context', context),
        ],
      );
      
      debugPrint('🔍 Error recorded: $exception');
      
    } catch (e) {
      debugPrint('Failed to record error: $e');
    }
  }

  /// Start performance trace
  Trace? startTrace(String traceName) {
    if (!_isInitialized) return null;
    
    try {
      final trace = _performance.newTrace(traceName);
      trace.start();
      return trace;
    } catch (e) {
      debugPrint('Failed to start trace $traceName: $e');
      return null;
    }
  }

  /// Stop performance trace
  Future<void> stopTrace(Trace? trace, {Map<String, String>? attributes}) async {
    if (trace == null) return;
    
    try {
      // Add attributes if provided
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }
      
      await trace.stop();
    } catch (e) {
      debugPrint('Failed to stop trace: $e');
    }
  }

  /// Track screen views
  Future<void> trackScreenView(String screenName, {String? screenClass}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      
      await _crashlytics.log('Screen view: $screenName');
      
    } catch (e) {
      debugPrint('Failed to track screen view: $e');
    }
  }

  /// Business Metrics - Order Events
  Future<void> trackOrderEvent(String eventType, {
    String? orderId,
    double? orderValue,
    String? paymentMethod,
    int? itemCount,
    Map<String, dynamic>? additionalData,
  }) async {
    await logEvent('order_$eventType', {
      'order_id': orderId,
      'order_value': orderValue,
      'payment_method': paymentMethod,
      'item_count': itemCount,
      'currency': 'INR',
      ...?additionalData,
    });
  }

  /// Business Metrics - Payment Events
  Future<void> trackPaymentEvent(String eventType, {
    String? paymentId,
    String? orderId,
    double? amount,
    String? paymentMethod,
    String? status,
    String? errorCode,
    Map<String, dynamic>? additionalData,
  }) async {
    await logEvent('payment_$eventType', {
      'payment_id': paymentId,
      'order_id': orderId,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status,
      'error_code': errorCode,
      'currency': 'INR',
      ...?additionalData,
    });
  }

  /// Business Metrics - User Journey Events
  Future<void> trackUserJourney(String journeyStep, {
    String? source,
    String? destination,
    Duration? duration,
    Map<String, dynamic>? additionalData,
  }) async {
    await logEvent('user_journey_$journeyStep', {
      'source': source,
      'destination': destination,
      'duration_ms': duration?.inMilliseconds,
      ...?additionalData,
    });
  }

  /// Business Metrics - Performance Events
  Future<void> trackPerformanceMetric(String metricName, {
    Duration? duration,
    int? count,
    double? value,
    Map<String, dynamic>? additionalData,
  }) async {
    await logEvent('performance_$metricName', {
      'duration_ms': duration?.inMilliseconds,
      'count': count,
      'value': value,
      ...?additionalData,
    });
  }

  /// Get monitoring status
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _userId;
  Map<String, dynamic> get userProperties => Map.from(_userProperties);
}
