import 'dart:io';
import 'dart:async';

/// Fast and reliable connectivity checker
/// Uses multiple HTTP requests to verify actual internet connectivity
class ConnectivityChecker {
  static const Duration _checkTimeout = Duration(seconds: 3); // 3 second timeout
  static const List<String> _testUrls = [
    'https://www.google.com',
    'https://httpbin.org/status/200', // Simple HTTP endpoint
    'https://www.cloudflare.com',
  ];

  /// Quick internet connectivity check
  /// Returns true if internet is available, false otherwise
  static Future<bool> hasConnection() async {
    try {
      // Try HTTP requests to verify actual internet
      for (String url in _testUrls) {
        try {
          final client = HttpClient();
          client.connectionTimeout = _checkTimeout;

          final request = await client.getUrl(Uri.parse(url))
              .timeout(_checkTimeout);

          final response = await request.close()
              .timeout(_checkTimeout);

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
      final socket = await Socket.connect('8.8.8.8', 53, timeout: _checkTimeout);
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
      yield await hasConnection();
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
