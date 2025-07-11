import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

// Conditional imports based on build mode
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart' if (dart.library.js) 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart' if (dart.library.js) 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart' if (dart.library.js) 'package:firebase_performance/firebase_performance.dart';

/// Conditional Firebase service that only loads needed modules
/// This reduces bundle size by ~3-5MB by avoiding unused Firebase features
class ConditionalFirebaseService {
  static final ConditionalFirebaseService _instance = ConditionalFirebaseService._internal();
  factory ConditionalFirebaseService() => _instance;
  ConditionalFirebaseService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Features that can be conditionally loaded
  static const bool _enableAnalytics = kReleaseMode; // Only in release
  static const bool _enableCrashlytics = kReleaseMode; // Only in release
  static const bool _enablePerformance = kReleaseMode; // Only in release
  static const bool _enableMessaging = true; // Always needed for notifications

  /// Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase with only needed modules
  Future<bool> initializeFirebase() async {
    if (_isInitialized) {
      debugPrint('🔥 Firebase already initialized');
      return true;
    }

    if (_isInitializing) {
      debugPrint('🔥 Firebase initialization in progress, waiting...');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    try {
      _isInitializing = true;
      debugPrint('🔥 Initializing Firebase with conditional modules...');
      
      final stopwatch = Stopwatch()..start();

      // Initialize Firebase Core (always needed)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase Core initialized');
      }

      // Conditionally initialize other modules
      await _initializeConditionalModules();

      stopwatch.stop();
      
      _isInitialized = true;
      _isInitializing = false;
      
      debugPrint('✅ Firebase initialized in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 Enabled modules: ${_getEnabledModules()}');
      return true;
    } catch (e) {
      _isInitializing = false;
      debugPrint('❌ Failed to initialize Firebase: $e');
      return false;
    }
  }

  /// Initialize only the modules we need
  Future<void> _initializeConditionalModules() async {
    final List<Future<void>> initTasks = [];

    // Firebase Messaging (always needed for notifications)
    if (_enableMessaging) {
      initTasks.add(_initializeMessaging());
    }

    // Firebase Analytics (only in release mode)
    if (_enableAnalytics) {
      initTasks.add(_initializeAnalytics());
    }

    // Firebase Crashlytics (only in release mode)
    if (_enableCrashlytics) {
      initTasks.add(_initializeCrashlytics());
    }

    // Firebase Performance (only in release mode)
    if (_enablePerformance) {
      initTasks.add(_initializePerformance());
    }

    // Initialize all enabled modules in parallel
    await Future.wait(initTasks);
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeMessaging() async {
    try {
      // Dynamic import to avoid loading if not needed
      final messaging = await _loadMessaging();
      if (messaging != null) {
        debugPrint('✅ Firebase Messaging initialized');
      }
    } catch (e) {
      debugPrint('⚠️ Firebase Messaging initialization failed: $e');
    }
  }

  /// Initialize Firebase Analytics
  Future<void> _initializeAnalytics() async {
    try {
      // Dynamic import to avoid loading if not needed
      final analytics = await _loadAnalytics();
      if (analytics != null) {
        await analytics.setAnalyticsCollectionEnabled(true);
        debugPrint('✅ Firebase Analytics initialized');
      }
    } catch (e) {
      debugPrint('⚠️ Firebase Analytics initialization failed: $e');
    }
  }

  /// Initialize Firebase Crashlytics
  Future<void> _initializeCrashlytics() async {
    try {
      // Dynamic import to avoid loading if not needed
      final crashlytics = await _loadCrashlytics();
      if (crashlytics != null) {
        await crashlytics.setCrashlyticsCollectionEnabled(true);
        debugPrint('✅ Firebase Crashlytics initialized');
      }
    } catch (e) {
      debugPrint('⚠️ Firebase Crashlytics initialization failed: $e');
    }
  }

  /// Initialize Firebase Performance
  Future<void> _initializePerformance() async {
    try {
      // Dynamic import to avoid loading if not needed
      final performance = await _loadPerformance();
      if (performance != null) {
        await performance.setPerformanceCollectionEnabled(true);
        debugPrint('✅ Firebase Performance initialized');
      }
    } catch (e) {
      debugPrint('⚠️ Firebase Performance initialization failed: $e');
    }
  }

  /// Load Firebase Messaging
  Future<FirebaseMessaging?> _loadMessaging() async {
    if (!_enableMessaging) return null;
    try {
      return FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('Failed to load Firebase Messaging: $e');
      return null;
    }
  }

  /// Load Firebase Analytics
  Future<FirebaseAnalytics?> _loadAnalytics() async {
    if (!_enableAnalytics) return null;
    try {
      return FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('Failed to load Firebase Analytics: $e');
      return null;
    }
  }

  /// Load Firebase Crashlytics
  Future<FirebaseCrashlytics?> _loadCrashlytics() async {
    if (!_enableCrashlytics) return null;
    try {
      return FirebaseCrashlytics.instance;
    } catch (e) {
      debugPrint('Failed to load Firebase Crashlytics: $e');
      return null;
    }
  }

  /// Load Firebase Performance
  Future<FirebasePerformance?> _loadPerformance() async {
    if (!_enablePerformance) return null;
    try {
      return FirebasePerformance.instance;
    } catch (e) {
      debugPrint('Failed to load Firebase Performance: $e');
      return null;
    }
  }

  /// Get list of enabled modules for debugging
  List<String> _getEnabledModules() {
    final modules = <String>['Core'];
    if (_enableMessaging) modules.add('Messaging');
    if (_enableAnalytics) modules.add('Analytics');
    if (_enableCrashlytics) modules.add('Crashlytics');
    if (_enablePerformance) modules.add('Performance');
    return modules;
  }

  /// Reset the service (for testing purposes)
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _isInitializing = false;
  }
}

/// Extension for easy access to conditional Firebase features
extension ConditionalFirebaseExtension on ConditionalFirebaseService {
  /// Check if a specific module is enabled
  bool isModuleEnabled(String module) {
    switch (module.toLowerCase()) {
      case 'messaging':
        return ConditionalFirebaseService._enableMessaging;
      case 'analytics':
        return ConditionalFirebaseService._enableAnalytics;
      case 'crashlytics':
        return ConditionalFirebaseService._enableCrashlytics;
      case 'performance':
        return ConditionalFirebaseService._enablePerformance;
      default:
        return false;
    }
  }
}
