# Network Error Handling Implementation Guide

## 🎯 Fixes Implemented

### ✅ **Fix 1: Home Screen Connectivity Flickering** 
**Problem:** FutureBuilder calling `ConnectivityChecker.hasConnection()` on every rebuild causing flickering errors
**Solution:** Created `ConnectivityNotifier` with cached state and periodic checks

**Files Modified:**
- `apps/mobile/lib/presentation/providers/network_providers.dart` - New connectivity provider
- `apps/mobile/lib/presentation/screens/home/clean_home_screen.dart` - Updated to use provider

**Key Changes:**
```dart
// OLD: Problematic FutureBuilder
return FutureBuilder<bool>(
  future: ConnectivityChecker.hasConnection(fastMode: true),
  builder: (context, snapshot) {
    // This rebuilds and makes HTTP requests constantly!
  }
);

// NEW: Cached connectivity state
final isConnected = ref.watch(isConnectedProvider);
if (!isConnected) {
  return NetworkErrorWidgets.connectionProblem(
    onRetry: () {
      ref.read(connectivityProvider.notifier).refresh();
      _performOptimisticRetry(ref);
    },
  );
}
```

### ✅ **Fix 2: Global Timeout Strategy**
**Problem:** No standardized timeouts across HTTP operations
**Solution:** Created centralized `NetworkConfig` with operation-specific timeouts

**Files Created:**
- `apps/mobile/lib/core/config/network_config.dart` - Centralized configuration

**Key Features:**
- **Data operations:** 10 seconds
- **File uploads:** 30 seconds  
- **Image loading:** 15 seconds
- **Connectivity checks:** 2 seconds
- **Authentication:** 8 seconds
- **Cart operations:** 8 seconds
- **Order operations:** 15 seconds

**Files Updated:**
- `apps/mobile/lib/core/services/network_service.dart` - Uses NetworkConfig.dataTimeout
- `apps/mobile/lib/core/services/connectivity_checker.dart` - Uses NetworkConfig timeouts

### ✅ **Fix 3: Comprehensive Error Logging**
**Problem:** No production error tracking and limited debugging information
**Solution:** Created `ErrorLoggingService` with Firebase Crashlytics integration

**Files Created:**
- `apps/mobile/lib/core/services/error_logging_service.dart` - Comprehensive logging service

**Key Features:**
- **Network errors:** Operation context, retry attempts, user ID
- **Repository errors:** Repository name, method, error details
- **UI errors:** Screen, widget, user action context
- **Business errors:** Failure type, operation context
- **Performance issues:** Duration tracking, threshold monitoring

**Files Updated:**
- `apps/mobile/lib/core/error_handling/global_error_handler.dart` - Uses ErrorLoggingService
- `apps/mobile/lib/main.dart` - Initializes error logging

### ✅ **Fix 4: Standardized Error Handling Patterns**
**Problem:** Inconsistent error handling across repositories
**Solution:** Created `BaseRepository` with standardized patterns

**Files Created:**
- `apps/mobile/lib/core/repositories/base_repository.dart` - Base class for all repositories

**Key Features:**
- **Automatic retry:** Exponential backoff with configurable attempts
- **Error classification:** Network, auth, business logic, validation errors
- **Cache fallback:** Network-first with local cache fallback
- **Comprehensive logging:** All errors logged with context
- **Timeout handling:** Operation-specific timeouts
- **Parallel operations:** Execute multiple operations concurrently

**Files Updated:**
- `apps/mobile/lib/data/repositories/product_repository_impl.dart` - Example migration

---

## 🚀 Migration Guide for Existing Repositories

### Step 1: Update Repository Class
```dart
// OLD
class MyRepositoryImpl implements MyRepository {
  
// NEW  
class MyRepositoryImpl extends BaseRepository implements MyRepository {
```

### Step 2: Replace Manual Error Handling
```dart
// OLD: Manual try-catch with basic error handling
Future<Either<Failure, Data>> getData() async {
  try {
    final result = await dataSource.getData();
    return Right(result);
  } catch (e) {
    return Left(ServerFailure(message: e.toString()));
  }
}

// NEW: Use base repository error handling
Future<Either<Failure, Data>> getData() async {
  return executeWithErrorHandling(
    () async => await dataSource.getData(),
    operationType: NetworkOperation.data,
    operationName: 'get data',
  );
}
```

### Step 3: Add Cache Support (Optional)
```dart
// NEW: With cache fallback
Future<Either<Failure, Data>> getData() async {
  return executeWithCache<Data>(
    // Network operation
    () async => await remoteDataSource.getData(),
    // Cache operation  
    () async => await localDataSource.getCachedData(),
    // Cache store
    (data) async => await localDataSource.cacheData(data),
    operationType: NetworkOperation.data,
    operationName: 'get data',
  );
}
```

### Step 4: Handle Supabase Operations
```dart
// NEW: Supabase-specific error handling
Future<Either<Failure, Data>> getSupabaseData() async {
  return executeSupabaseQuery(
    () async => await supabaseClient.from('table').select(),
    operationName: 'get supabase data',
  );
}
```

---

## 🧪 Testing the Fixes

### Test 1: Home Screen Connectivity
1. **Open the app** and navigate to home screen
2. **Turn off WiFi/mobile data** briefly
3. **Turn connectivity back on**
4. **Expected:** No flickering error messages, smooth transitions

### Test 2: Timeout Handling
1. **Simulate slow network** (use network throttling)
2. **Perform data operations** (load products, categories)
3. **Expected:** Operations timeout after configured duration, show appropriate error

### Test 3: Error Logging
1. **Trigger network errors** (disconnect internet during operations)
2. **Check Firebase Crashlytics** dashboard
3. **Expected:** Errors logged with context, operation details, user information

### Test 4: Retry Mechanisms
1. **Simulate intermittent connectivity**
2. **Perform operations** that should retry
3. **Expected:** Automatic retries with exponential backoff, eventual success or failure

---

## 📊 Monitoring and Metrics

### Key Metrics to Track
- **Error rates** by operation type
- **Retry success rates**
- **Average operation duration**
- **Timeout frequency**
- **Cache hit rates**

### Firebase Crashlytics Custom Keys
- `last_network_operation` - Last network operation performed
- `last_error_type` - Type of last error (network, repository, ui, business)
- `last_repository` - Last repository that had an error
- `last_screen` - Last screen where error occurred
- `user_id` - Current user identifier

### Performance Thresholds
- **Data operations:** > 10 seconds = performance issue
- **Image loading:** > 15 seconds = performance issue  
- **Search operations:** > 6 seconds = performance issue
- **Cart operations:** > 8 seconds = performance issue

---

## 🔧 Configuration Options

### Network Quality Adaptation
```dart
// Automatically adjust timeouts based on network speed
final config = NetworkConfig.getConfigForBandwidth('slow');
// Returns: { timeout_multiplier: 2.0, retry_attempts: 2, ... }
```

### Error Logging Control
```dart
// Enable/disable crash reporting
await ErrorLoggingService.instance.setCrashReportingEnabled(true);

// Set user context for better error tracking
ErrorLoggingService.instance.setUserContext(
  userId: 'user123',
  email: 'user@example.com',
  additionalData: {'subscription': 'premium'},
);
```

### Connectivity Monitoring
```dart
// Listen to connectivity changes
ref.listen(connectivityProvider, (previous, next) {
  if (next.isConnected && previous?.isDisconnected == true) {
    // Connection restored - sync pending operations
  }
});
```

---

## 🎯 Next Steps

### Immediate (This Week)
1. **Test all fixes** in development environment
2. **Update remaining repositories** to use BaseRepository
3. **Configure Firebase Crashlytics** project settings
4. **Set up monitoring dashboards**

### Short Term (2 Weeks)  
1. **Deploy to staging** environment
2. **Conduct load testing** with error injection
3. **Monitor error rates** and performance metrics
4. **Fine-tune timeout values** based on real usage

### Medium Term (1 Month)
1. **Implement circuit breaker** pattern for failing services
2. **Add predictive error handling** based on patterns
3. **Create automated error recovery** workflows
4. **Optimize cache strategies** based on usage patterns

---

## 🚨 Rollback Plan

If issues arise, rollback steps:

1. **Revert home screen** to original FutureBuilder (temporary fix)
2. **Disable error logging** service initialization
3. **Use original repository** implementations
4. **Restore original timeout** values

**Rollback files:**
- `apps/mobile/lib/presentation/screens/home/clean_home_screen.dart`
- `apps/mobile/lib/main.dart` 
- `apps/mobile/lib/data/repositories/product_repository_impl.dart`

---

*This implementation provides a solid foundation for production-ready network error handling. The modular approach allows for gradual migration and easy rollback if needed.*
