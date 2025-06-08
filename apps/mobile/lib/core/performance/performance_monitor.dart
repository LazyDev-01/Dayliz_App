import 'package:flutter/foundation.dart';
import 'dart:async';

/// Performance monitoring utility to track app performance improvements
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  static PerformanceMonitor get instance => _instance;

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _measurements = {};
  final Map<String, int> _counters = {};

  /// Start timing an operation
  void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
    debugPrint('⏱️ Started timing: $operation');
  }

  /// End timing an operation and record the duration
  Duration? endTimer(String operation) {
    final startTime = _startTimes[operation];
    if (startTime == null) {
      debugPrint('❌ No start time found for operation: $operation');
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(operation);

    // Store measurement
    _measurements.putIfAbsent(operation, () => []).add(duration);
    
    debugPrint('✅ $operation completed in ${duration.inMilliseconds}ms');
    return duration;
  }

  /// Increment a counter
  void incrementCounter(String counter) {
    _counters[counter] = (_counters[counter] ?? 0) + 1;
  }

  /// Get average duration for an operation
  Duration? getAverageDuration(String operation) {
    final measurements = _measurements[operation];
    if (measurements == null || measurements.isEmpty) {
      return null;
    }

    final totalMs = measurements.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    final averageMs = totalMs / measurements.length;
    return Duration(milliseconds: averageMs.round());
  }

  /// Get performance statistics
  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};

    // Add timing statistics
    for (final operation in _measurements.keys) {
      final measurements = _measurements[operation]!;
      final totalMs = measurements.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
      final averageMs = totalMs / measurements.length;
      final minMs = measurements.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
      final maxMs = measurements.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

      stats[operation] = {
        'count': measurements.length,
        'average_ms': averageMs.round(),
        'min_ms': minMs,
        'max_ms': maxMs,
        'total_ms': totalMs,
      };
    }

    // Add counters
    stats['counters'] = Map.from(_counters);

    return stats;
  }

  /// Print performance report
  void printReport() {
    if (!kDebugMode) return;

    debugPrint('\n📊 PERFORMANCE REPORT');
    debugPrint('=' * 50);

    final stats = getStats();
    
    // Print timing statistics
    for (final operation in stats.keys) {
      if (operation == 'counters') continue;
      
      final operationStats = stats[operation] as Map<String, dynamic>;
      debugPrint('🔍 $operation:');
      debugPrint('   Count: ${operationStats['count']}');
      debugPrint('   Average: ${operationStats['average_ms']}ms');
      debugPrint('   Min: ${operationStats['min_ms']}ms');
      debugPrint('   Max: ${operationStats['max_ms']}ms');
      debugPrint('   Total: ${operationStats['total_ms']}ms');
      debugPrint('');
    }

    // Print counters
    final counters = stats['counters'] as Map<String, dynamic>;
    if (counters.isNotEmpty) {
      debugPrint('📈 COUNTERS:');
      for (final counter in counters.keys) {
        debugPrint('   $counter: ${counters[counter]}');
      }
      debugPrint('');
    }

    debugPrint('=' * 50);
  }

  /// Clear all measurements
  void clear() {
    _startTimes.clear();
    _measurements.clear();
    _counters.clear();
    debugPrint('🧹 Performance measurements cleared');
  }

  /// Time a future operation
  static Future<T> timeOperation<T>(String operation, Future<T> Function() function) async {
    instance.startTimer(operation);
    try {
      final result = await function();
      instance.endTimer(operation);
      return result;
    } catch (e) {
      instance.endTimer(operation);
      rethrow;
    }
  }

  /// Time a synchronous operation
  static T timeSync<T>(String operation, T Function() function) {
    instance.startTimer(operation);
    try {
      final result = function();
      instance.endTimer(operation);
      return result;
    } catch (e) {
      instance.endTimer(operation);
      rethrow;
    }
  }
}

/// Performance tracking mixin for widgets
mixin PerformanceTrackingMixin {
  void trackOperation(String operation, VoidCallback function) {
    PerformanceMonitor.timeSync(operation, () {
      function();
      return null;
    });
  }

  Future<T> trackAsyncOperation<T>(String operation, Future<T> Function() function) {
    return PerformanceMonitor.timeOperation(operation, function);
  }
}

/// Performance metrics for specific operations
class PerformanceMetrics {
  static const String productListLoad = 'product_list_load';
  static const String productSearch = 'product_search';
  static const String cartOperation = 'cart_operation';
  static const String imageLoad = 'image_load';
  static const String cacheRead = 'cache_read';
  static const String cacheWrite = 'cache_write';
  static const String databaseQuery = 'database_query';
  static const String apiRequest = 'api_request';
  static const String screenTransition = 'screen_transition';
  static const String widgetBuild = 'widget_build';

  // Counters
  static const String productViews = 'product_views';
  static const String searchQueries = 'search_queries';
  static const String cartAdditions = 'cart_additions';
  static const String cacheHits = 'cache_hits';
  static const String cacheMisses = 'cache_misses';
}

/// Extension for easy performance tracking
extension PerformanceTrackingExtension on Future {
  Future<T> trackPerformance<T>(String operation) {
    return PerformanceMonitor.timeOperation(operation, () => this as Future<T>);
  }
}
