import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'monitoring_service.dart';
import 'business_metrics_service.dart';

/// App Monitoring Integration Service
/// 
/// Integrates monitoring across the entire Dayliz app:
/// - App lifecycle monitoring
/// - Network connectivity monitoring
/// - Performance monitoring
/// - Error tracking
/// - User experience metrics
class AppMonitoringIntegration {
  static final AppMonitoringIntegration _instance = AppMonitoringIntegration._internal();
  factory AppMonitoringIntegration() => _instance;
  AppMonitoringIntegration._internal();

  final MonitoringService _monitoring = MonitoringService();
  final BusinessMetricsService _businessMetrics = BusinessMetricsService();
  
  // Connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  ConnectivityResult? _lastConnectivityResult;
  
  // Performance monitoring
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, int> _operationCounts = {};
  
  // Error tracking
  int _errorCount = 0;
  DateTime? _lastErrorTime;
  
  // App state tracking
  AppLifecycleState? _lastAppState;
  DateTime? _appStartTime;
  DateTime? _lastInteractionTime;

  /// Initialize comprehensive app monitoring
  Future<void> initialize() async {
    try {
      _appStartTime = DateTime.now();
      
      // Initialize core monitoring services
      await _monitoring.initialize();
      await _businessMetrics.initialize();
      
      // Set up connectivity monitoring
      await _setupConnectivityMonitoring();
      
      // Set up app lifecycle monitoring
      _setupAppLifecycleMonitoring();
      
      // Set up error monitoring
      _setupErrorMonitoring();
      
      // Track app initialization
      await _trackAppInitialization();
      
      debugPrint('✅ AppMonitoringIntegration initialized successfully');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize AppMonitoringIntegration: $e');
      await _monitoring.recordError(e, stackTrace, reason: 'Failed to initialize monitoring');
    }
  }

  /// Set up connectivity monitoring
  Future<void> _setupConnectivityMonitoring() async {
    try {
      // Get initial connectivity state
      _lastConnectivityResult = await _connectivity.checkConnectivity();
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (ConnectivityResult result) async {
          await _handleConnectivityChange(result);
        },
        onError: (error) async {
          await _monitoring.recordError(error, null, reason: 'Connectivity monitoring error');
        },
      );
      
      // Track initial connectivity
      await _monitoring.logEvent('connectivity_initial', {
        'connection_type': _lastConnectivityResult.toString(),
      });
      
    } catch (e) {
      debugPrint('Failed to setup connectivity monitoring: $e');
    }
  }

  /// Handle connectivity changes
  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    try {
      final previousResult = _lastConnectivityResult;
      _lastConnectivityResult = result;
      
      // Track connectivity change
      await _monitoring.logEvent('connectivity_changed', {
        'from': previousResult.toString(),
        'to': result.toString(),
        'is_connected': result != ConnectivityResult.none,
      });
      
      // Track business impact
      if (result == ConnectivityResult.none) {
        await _businessMetrics.trackErrorEvent('network_disconnected', 
          errorMessage: 'Device lost network connectivity'
        );
      } else if (previousResult == ConnectivityResult.none) {
        await _businessMetrics.trackErrorEvent('network_reconnected',
          errorMessage: 'Device regained network connectivity'
        );
      }
      
    } catch (e) {
      debugPrint('Failed to handle connectivity change: $e');
    }
  }

  /// Set up app lifecycle monitoring
  void _setupAppLifecycleMonitoring() {
    try {
      WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
    } catch (e) {
      debugPrint('Failed to setup app lifecycle monitoring: $e');
    }
  }

  /// Handle app lifecycle state changes
  Future<void> _handleAppLifecycleStateChange(AppLifecycleState state) async {
    try {
      final previousState = _lastAppState;
      _lastAppState = state;
      
      // Track app state change
      await _monitoring.logEvent('app_lifecycle_changed', {
        'from': previousState?.toString(),
        'to': state.toString(),
      });
      
      // Handle specific state changes
      switch (state) {
        case AppLifecycleState.resumed:
          await _handleAppResumed();
          break;
        case AppLifecycleState.paused:
          await _handleAppPaused();
          break;
        case AppLifecycleState.detached:
          await _handleAppDetached();
          break;
        case AppLifecycleState.inactive:
          // App is inactive (e.g., during phone call)
          break;
        case AppLifecycleState.hidden:
          // App is hidden
          break;
      }
      
    } catch (e) {
      debugPrint('Failed to handle app lifecycle change: $e');
    }
  }

  /// Handle app resumed
  Future<void> _handleAppResumed() async {
    await _businessMetrics.trackEngagementEvent('app_resumed');
    
    // Check if this is a cold start or warm start
    if (_appStartTime != null) {
      final timeSinceStart = DateTime.now().difference(_appStartTime!);
      if (timeSinceStart.inMinutes < 1) {
        await _businessMetrics.trackAppLaunch(
          initializationTime: timeSinceStart,
          isFirstLaunch: false,
          launchSource: 'resume',
        );
      }
    }
  }

  /// Handle app paused
  Future<void> _handleAppPaused() async {
    await _businessMetrics.trackEngagementEvent('app_paused');
    
    // Track session if user was active
    if (_lastInteractionTime != null) {
      final sessionDuration = DateTime.now().difference(_lastInteractionTime!);
      await _monitoring.trackPerformanceMetric('session_duration',
        duration: sessionDuration,
      );
    }
  }

  /// Handle app detached
  Future<void> _handleAppDetached() async {
    await _businessMetrics.trackSessionEnd();
    
    // Clean up resources
    await _cleanup();
  }

  /// Set up error monitoring
  void _setupErrorMonitoring() {
    // Flutter error handling is already set up in MonitoringService
    // This method can be extended for additional error tracking
  }

  /// Track app initialization metrics
  Future<void> _trackAppInitialization() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      Map<String, dynamic> deviceData = {};
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData = {
          'platform': 'android',
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData = {
          'platform': 'ios',
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      }
      
      await _businessMetrics.trackAppLaunch(
        initializationTime: DateTime.now().difference(_appStartTime!),
        isFirstLaunch: true, // TODO: Implement first launch detection
        launchSource: 'cold_start',
      );
      
      await _monitoring.setUserProperties(deviceData);
      
    } catch (e) {
      debugPrint('Failed to track app initialization: $e');
    }
  }

  /// Track user interaction
  Future<void> trackUserInteraction(String interactionType, {
    String? screen,
    String? element,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _lastInteractionTime = DateTime.now();
      
      await _monitoring.logEvent('user_interaction', {
        'interaction_type': interactionType,
        'screen': screen,
        'element': element,
        ...?additionalData,
      });
      
    } catch (e) {
      debugPrint('Failed to track user interaction: $e');
    }
  }

  /// Start operation tracking
  void startOperation(String operationName) {
    try {
      _operationStartTimes[operationName] = DateTime.now();
      _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
    } catch (e) {
      debugPrint('Failed to start operation tracking: $e');
    }
  }

  /// End operation tracking
  Future<void> endOperation(String operationName, {
    bool success = true,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final startTime = _operationStartTimes.remove(operationName);
      if (startTime == null) return;
      
      final duration = DateTime.now().difference(startTime);
      
      await _monitoring.trackPerformanceMetric(operationName,
        duration: duration,
        additionalData: {
          'success': success,
          'error_message': errorMessage,
          'operation_count': _operationCounts[operationName] ?? 1,
          ...?additionalData,
        }
      );
      
      if (!success) {
        await _businessMetrics.trackErrorEvent('operation_failed',
          errorMessage: errorMessage ?? 'Operation failed',
          screen: additionalData?['screen'],
          action: operationName,
          context: additionalData,
        );
      }
      
    } catch (e) {
      debugPrint('Failed to end operation tracking: $e');
    }
  }

  /// Track API call performance
  Future<void> trackApiCall(String endpoint, {
    required Duration duration,
    required int statusCode,
    String? method,
    String? errorMessage,
  }) async {
    try {
      final success = statusCode >= 200 && statusCode < 300;
      
      await _businessMetrics.trackPerformanceEvent('api_call',
        responseTime: duration,
        endpoint: endpoint,
        success: success,
        errorType: success ? null : 'http_$statusCode',
      );
      
      if (!success) {
        await _businessMetrics.trackErrorEvent('api_error',
          errorMessage: errorMessage ?? 'API call failed',
          context: {
            'endpoint': endpoint,
            'method': method,
            'status_code': statusCode,
            'duration_ms': duration.inMilliseconds,
          },
        );
      }
      
    } catch (e) {
      debugPrint('Failed to track API call: $e');
    }
  }

  /// Track memory usage
  Future<void> trackMemoryUsage() async {
    try {
      // This is a simplified memory tracking
      // In production, you might want to use more sophisticated memory monitoring
      await _monitoring.logEvent('memory_check', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      debugPrint('Failed to track memory usage: $e');
    }
  }

  /// Get monitoring status
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'monitoring_initialized': _monitoring.isInitialized,
      'connectivity': _lastConnectivityResult?.toString(),
      'app_state': _lastAppState?.toString(),
      'error_count': _errorCount,
      'last_error_time': _lastErrorTime?.toIso8601String(),
      'operation_counts': Map.from(_operationCounts),
      'uptime_seconds': _appStartTime != null 
        ? DateTime.now().difference(_appStartTime!).inSeconds 
        : 0,
    };
  }

  /// Clean up resources
  Future<void> _cleanup() async {
    try {
      await _connectivitySubscription?.cancel();
      _operationStartTimes.clear();
      _operationCounts.clear();
    } catch (e) {
      debugPrint('Failed to cleanup monitoring: $e');
    }
  }

  /// Dispose monitoring integration
  Future<void> dispose() async {
    await _cleanup();
  }
}

/// App lifecycle observer for monitoring
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final AppMonitoringIntegration _integration;
  
  _AppLifecycleObserver(this._integration);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _integration._handleAppLifecycleStateChange(state);
  }
}
