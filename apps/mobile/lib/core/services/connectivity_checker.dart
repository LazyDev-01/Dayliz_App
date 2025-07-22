import 'dart:io';
import 'dart:async';

import '../config/network_config.dart';

/// Fast and reliable connectivity checker
/// Uses multiple HTTP requests to verify actual internet connectivity
class ConnectivityChecker {
  // Use centralized timeout configuration
  static Duration get _fastTimeout => NetworkConfig.connectivityUrlTimeout;
  static Duration get _normalTimeout => NetworkConfig.connectivityTimeout;

  // Use centralized URL configuration
  static List<String> get _testUrls => NetworkConfig.connectivityTestUrls;

  /// Quick internet connectivity check with parallel testing
  /// Returns true if internet is available, false otherwise
  /// Uses parallel requests for maximum speed (1-2 seconds max)
  static Future<bool> hasConnection({bool fastMode = false}) async {
    try {
      final timeout = fastMode ? _fastTimeout : _normalTimeout;

      // Test all URLs in parallel for maximum speed
      final futures = _testUrls.map((url) => _testSingleUrl(url, timeout));

      // Return true as soon as ANY URL succeeds
      final results = await Future.wait(
        futures,
        eagerError: false, // Don't stop on first error
      );

      // Return true if any connection succeeded
      return results.any((result) => result);
    } catch (e) {
      return false; // General error
    }
  }

  /// Test a single URL with timeout
  static Future<bool> _testSingleUrl(String url, Duration timeout) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = timeout;

      final request = await client.getUrl(Uri.parse(url))
          .timeout(timeout);

      final response = await request.close()
          .timeout(timeout);

      client.close();

      // Check if we got a successful response
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false; // This URL failed
    }
  }

  /// Legacy method for backward compatibility
  /// @deprecated Use hasConnection() instead
  static Future<bool> hasConnectionLegacy() async {
    try {
      // Try HTTP requests to verify actual internet (old sequential method)
      for (String url in _testUrls) {
        try {
          final client = HttpClient();
          client.connectionTimeout = _normalTimeout;

          final request = await client.getUrl(Uri.parse(url))
              .timeout(_normalTimeout);

          final response = await request.close()
              .timeout(_normalTimeout);

          client.close();

          // Check if we got a successful response
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return true; // Found working connection
          }
        } catch (e) {
          // Try next URL
          continue;
        }
      }

      return false; // All URLs failed
    } catch (e) {
      return false; // General error
    }
  }

  /// Alternative connectivity check using ping-like approach
  static Future<bool> hasConnectionAlternative() async {
    try {
      // Try a simple socket connection
      final socket = await Socket.connect('8.8.8.8', 53, timeout: _normalTimeout);
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check connectivity with detailed result
  static Future<ConnectivityResult> checkConnectivityDetailed() async {
    final startTime = DateTime.now();

    try {
      // Try primary HTTP method first
      bool hasInternet = await hasConnection();

      // If HTTP method fails, try alternative socket method
      if (!hasInternet) {
        hasInternet = await hasConnectionAlternative();
      }

      final duration = DateTime.now().difference(startTime);

      return ConnectivityResult(
        hasConnection: hasInternet,
        checkDuration: duration,
        errorMessage: hasInternet ? null : 'No internet connection detected',
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      return ConnectivityResult(
        hasConnection: false,
        checkDuration: duration,
        errorMessage: 'Connectivity check failed: ${e.toString()}',
      );
    }
  }

  /// Stream for monitoring connectivity changes
  static Stream<bool> connectivityStream() async* {
    while (true) {
      yield await hasConnection(fastMode: true); // Use fast mode for monitoring
      await Future.delayed(const Duration(seconds: 5)); // Check every 5 seconds
    }
  }
}

/// Result of connectivity check with details
class ConnectivityResult {
  final bool hasConnection;
  final Duration checkDuration;
  final String? errorMessage;

  const ConnectivityResult({
    required this.hasConnection,
    required this.checkDuration,
    this.errorMessage,
  });

  bool get isConnected => hasConnection;
  bool get isFast => checkDuration.inMilliseconds < 1000; // Under 1 second is considered fast
  
  @override
  String toString() {
    return 'ConnectivityResult(connected: $hasConnection, duration: ${checkDuration.inMilliseconds}ms, error: $errorMessage)';
  }
}
