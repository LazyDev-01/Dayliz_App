/// Global network configuration for consistent timeout and retry strategies
/// across the entire Dayliz app
class NetworkConfig {
  // ==================== TIMEOUT CONFIGURATIONS ====================
  
  /// Standard timeout for data fetching operations (products, categories, etc.)
  static const Duration dataTimeout = Duration(seconds: 10);
  
  /// Timeout for file upload operations (images, documents)
  static const Duration uploadTimeout = Duration(seconds: 30);
  
  /// Timeout for image loading and caching
  static const Duration imageTimeout = Duration(seconds: 15);
  
  /// Fast timeout for connectivity checks (increased for better reliability)
  static const Duration connectivityTimeout = Duration(seconds: 5);

  /// Timeout for authentication operations
  static const Duration authTimeout = Duration(seconds: 8);
  
  /// Timeout for real-time operations (notifications, live updates)
  static const Duration realtimeTimeout = Duration(seconds: 5);
  
  /// Timeout for search operations
  static const Duration searchTimeout = Duration(seconds: 6);
  
  /// Timeout for cart operations (add, remove, update)
  static const Duration cartTimeout = Duration(seconds: 8);
  
  /// Timeout for order operations (place order, payment)
  static const Duration orderTimeout = Duration(seconds: 15);
  
  // ==================== RETRY CONFIGURATIONS ====================
  
  /// Maximum retry attempts for network operations
  static const int maxRetryAttempts = 3;
  
  /// Base delay between retry attempts
  static const Duration baseRetryDelay = Duration(seconds: 1);
  
  /// Maximum delay between retry attempts (for exponential backoff)
  static const Duration maxRetryDelay = Duration(seconds: 8);
  
  /// Retry attempts for critical operations (auth, payments)
  static const int criticalRetryAttempts = 2;
  
  /// Retry attempts for non-critical operations (images, analytics)
  static const int nonCriticalRetryAttempts = 1;
  
  // ==================== CONNECTION CONFIGURATIONS ====================
  
  /// URLs for connectivity testing (in order of preference)
  static const List<String> connectivityTestUrls = [
    'https://www.google.com',
    'https://httpbin.org/status/200',
    'https://www.cloudflare.com',
    'https://1.1.1.1', // Cloudflare DNS
  ];
  
  /// Interval for periodic connectivity checks
  static const Duration connectivityCheckInterval = Duration(seconds: 30);
  
  /// Timeout for individual connectivity test URLs (increased for reliability)
  static const Duration connectivityUrlTimeout = Duration(seconds: 3);
  
  // ==================== CACHE CONFIGURATIONS ====================
  
  /// Cache duration for API responses
  static const Duration apiCacheDuration = Duration(minutes: 5);
  
  /// Cache duration for images
  static const Duration imageCacheDuration = Duration(days: 7);
  
  /// Cache duration for static data (categories, zones)
  static const Duration staticDataCacheDuration = Duration(hours: 1);
  
  /// Maximum cache size for images (in MB)
  static const int maxImageCacheSize = 100;
  
  // ==================== ERROR HANDLING CONFIGURATIONS ====================
  
  /// HTTP status codes that should trigger a retry
  static const List<int> retryableStatusCodes = [
    408, // Request Timeout
    429, // Too Many Requests
    500, // Internal Server Error
    502, // Bad Gateway
    503, // Service Unavailable
    504, // Gateway Timeout
  ];
  
  /// HTTP status codes that should NOT trigger a retry
  static const List<int> nonRetryableStatusCodes = [
    400, // Bad Request
    401, // Unauthorized
    403, // Forbidden
    404, // Not Found
    422, // Unprocessable Entity
  ];
  
  // ==================== PERFORMANCE CONFIGURATIONS ====================
  
  /// Maximum concurrent network requests
  static const int maxConcurrentRequests = 6;
  
  /// Request priority levels
  static const int highPriority = 1;    // Auth, payments, critical data
  static const int normalPriority = 2;  // Products, categories, user data
  static const int lowPriority = 3;     // Images, analytics, non-critical
  
  /// Bandwidth-based configurations
  static const Map<String, Map<String, dynamic>> bandwidthConfigs = {
    'slow': {
      'timeout_multiplier': 2.0,
      'retry_attempts': 2,
      'image_quality': 'low',
      'concurrent_requests': 3,
    },
    'normal': {
      'timeout_multiplier': 1.0,
      'retry_attempts': 3,
      'image_quality': 'medium',
      'concurrent_requests': 6,
    },
    'fast': {
      'timeout_multiplier': 0.8,
      'retry_attempts': 3,
      'image_quality': 'high',
      'concurrent_requests': 8,
    },
  };
  
  // ==================== HELPER METHODS ====================
  
  /// Get timeout for specific operation type
  static Duration getTimeoutForOperation(NetworkOperation operation) {
    switch (operation) {
      case NetworkOperation.data:
        return dataTimeout;
      case NetworkOperation.upload:
        return uploadTimeout;
      case NetworkOperation.image:
        return imageTimeout;
      case NetworkOperation.connectivity:
        return connectivityTimeout;
      case NetworkOperation.auth:
        return authTimeout;
      case NetworkOperation.realtime:
        return realtimeTimeout;
      case NetworkOperation.search:
        return searchTimeout;
      case NetworkOperation.cart:
        return cartTimeout;
      case NetworkOperation.order:
        return orderTimeout;
    }
  }
  
  /// Get retry attempts for operation priority
  static int getRetryAttemptsForPriority(int priority) {
    switch (priority) {
      case highPriority:
        return criticalRetryAttempts;
      case lowPriority:
        return nonCriticalRetryAttempts;
      default:
        return maxRetryAttempts;
    }
  }
  
  /// Calculate exponential backoff delay
  static Duration calculateBackoffDelay(int attemptNumber) {
    final delay = baseRetryDelay * (1 << (attemptNumber - 1)); // 2^(n-1)
    return delay > maxRetryDelay ? maxRetryDelay : delay;
  }
  
  /// Check if HTTP status code is retryable
  static bool isRetryableStatusCode(int statusCode) {
    return retryableStatusCodes.contains(statusCode);
  }
  
  /// Check if HTTP status code should not be retried
  static bool isNonRetryableStatusCode(int statusCode) {
    return nonRetryableStatusCodes.contains(statusCode);
  }
  
  /// Get configuration for current network bandwidth
  static Map<String, dynamic> getConfigForBandwidth(String bandwidth) {
    return bandwidthConfigs[bandwidth] ?? bandwidthConfigs['normal']!;
  }
}

/// Enum for different types of network operations
enum NetworkOperation {
  data,         // General data fetching
  upload,       // File uploads
  image,        // Image loading
  connectivity, // Connectivity checks
  auth,         // Authentication
  realtime,     // Real-time updates
  search,       // Search operations
  cart,         // Cart operations
  order,        // Order operations
}

/// Network operation priority levels
class NetworkPriority {
  static const int critical = 1;  // Auth, payments, critical user actions
  static const int high = 2;      // User data, cart, orders
  static const int normal = 3;    // Products, categories, general content
  static const int low = 4;       // Images, analytics, background tasks
}

/// Network quality levels for adaptive behavior
enum NetworkQuality {
  poor,    // < 1 Mbps
  slow,    // 1-5 Mbps
  normal,  // 5-25 Mbps
  fast,    // > 25 Mbps
}
