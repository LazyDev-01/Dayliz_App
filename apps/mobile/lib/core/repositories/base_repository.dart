import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../config/network_config.dart';
import '../errors/failures.dart';
import '../errors/exceptions.dart';
import '../services/error_logging_service.dart';

/// Base repository with standardized error handling and retry mechanisms
/// All repositories should extend this class for consistent behavior
abstract class BaseRepository {
  
  // ==================== CORE ERROR HANDLING ====================
  
  /// Execute a network operation with comprehensive error handling
  /// This is the main method that all repositories should use
  Future<Either<Failure, T>> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    NetworkOperation operationType = NetworkOperation.data,
    int priority = NetworkPriority.normal,
    bool enableRetry = true,
    String? operationName,
  }) async {
    final timeout = NetworkConfig.getTimeoutForOperation(operationType);
    final maxAttempts = enableRetry 
        ? NetworkConfig.getRetryAttemptsForPriority(priority)
        : 1;
    
    debugPrint('🌐 REPO: Starting ${operationName ?? 'operation'} (timeout: ${timeout.inSeconds}s, attempts: $maxAttempts)');
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await operation().timeout(timeout);
        
        if (attempt > 1) {
          debugPrint('✅ REPO: ${operationName ?? 'Operation'} succeeded on attempt $attempt');
        }
        
        return Right(result);
        
      } catch (e) {
        debugPrint('❌ REPO: ${operationName ?? 'Operation'} failed on attempt $attempt: $e');

        // Log the error for monitoring
        ErrorLoggingService.instance.logRepositoryError(
          error: e,
          repository: runtimeType.toString(),
          method: operationName ?? 'unknown',
          additionalData: {
            'attempt': attempt,
            'max_attempts': maxAttempts,
            'operation_type': operationType.toString(),
            'priority': priority,
          },
        );

        // If this is the last attempt, return the failure
        if (attempt == maxAttempts) {
          return Left(_mapExceptionToFailure(e, operationName));
        }
        
        // Check if we should retry this error
        if (!_shouldRetryError(e)) {
          debugPrint('🚫 REPO: Error not retryable, stopping attempts');
          return Left(_mapExceptionToFailure(e, operationName));
        }
        
        // Calculate delay for next attempt
        final delay = NetworkConfig.calculateBackoffDelay(attempt);
        debugPrint('⏳ REPO: Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }
    
    // This should never be reached, but just in case
    return Left(ServerFailure(message: 'Operation failed after $maxAttempts attempts'));
  }
  
  /// Execute multiple operations in parallel with error handling
  Future<Either<Failure, List<T>>> executeParallel<T>(
    List<Future<T> Function()> operations, {
    NetworkOperation operationType = NetworkOperation.data,
    int priority = NetworkPriority.normal,
    bool failFast = false,
  }) async {
    try {
      final futures = operations.map((op) => 
        executeWithErrorHandling(op, 
          operationType: operationType, 
          priority: priority
        )
      ).toList();
      
      final results = await Future.wait(futures);
      final List<T> successResults = [];
      
      for (final result in results) {
        if (result.isLeft() && failFast) {
          return result.fold(
            (failure) => Left(failure),
            (_) => Right(successResults), // This won't be reached
          );
        }

        result.fold(
          (failure) {
            // Continue collecting results even if some fail
          },
          (success) => successResults.add(success),
        );
      }
      
      return Right(successResults);
      
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'parallel operations'));
    }
  }
  
  // ==================== SUPABASE-SPECIFIC HELPERS ====================
  
  /// Execute Supabase query with error handling
  Future<Either<Failure, T>> executeSupabaseQuery<T>(
    Future<T> Function() query, {
    String? operationName,
    NetworkOperation operationType = NetworkOperation.data,
  }) async {
    return executeWithErrorHandling(
      query,
      operationType: operationType,
      operationName: operationName ?? 'Supabase query',
    );
  }
  
  /// Execute Supabase real-time operation
  Future<Either<Failure, T>> executeSupabaseRealtime<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    return executeWithErrorHandling(
      operation,
      operationType: NetworkOperation.realtime,
      priority: NetworkPriority.high,
      operationName: operationName ?? 'Supabase realtime',
    );
  }
  
  // ==================== CACHE HELPERS ====================
  
  /// Execute with cache fallback
  Future<Either<Failure, T>> executeWithCache<T>(
    Future<T> Function() networkOperation,
    Future<T?> Function() cacheOperation,
    Future<void> Function(T data) cacheStore, {
    NetworkOperation operationType = NetworkOperation.data,
    String? operationName,
  }) async {
    // Try network first
    final networkResult = await executeWithErrorHandling(
      networkOperation,
      operationType: operationType,
      operationName: operationName,
    );
    
    return networkResult.fold(
      (failure) async {
        // Network failed, try cache
        try {
          final cachedData = await cacheOperation();
          if (cachedData != null) {
            debugPrint('📦 REPO: Using cached data for ${operationName ?? 'operation'}');
            return Right(cachedData);
          }
        } catch (e) {
          debugPrint('❌ REPO: Cache fallback failed: $e');
        }
        
        // Both network and cache failed
        return Left(failure);
      },
      (data) async {
        // Network succeeded, update cache
        try {
          await cacheStore(data);
        } catch (e) {
          debugPrint('⚠️ REPO: Failed to update cache: $e');
          // Don't fail the operation if cache update fails
        }
        return Right(data);
      },
    );
  }
  
  // ==================== PRIVATE HELPER METHODS ====================
  
  /// Map exceptions to appropriate failures
  Failure _mapExceptionToFailure(dynamic error, String? operationName) {
    final context = operationName != null ? ' during $operationName' : '';
    
    // Timeout errors
    if (error is TimeoutException) {
      return NetworkFailure(message: 'Request timed out$context. Please check your connection.');
    }
    
    // Network connectivity errors
    if (error is SocketException) {
      return NetworkFailure(message: 'No internet connection$context. Please check your network.');
    }
    
    // Supabase-specific errors
    if (error is PostgrestException) {
      return _handlePostgrestException(error, context);
    }
    
    if (error is AuthException) {
      return AuthFailure(message: 'Authentication failed$context: ${error.message}');
    }
    
    if (error is StorageException) {
      return ServerFailure(message: 'Storage operation failed$context: ${error.message}');
    }
    
    // HTTP errors
    if (error is HttpException) {
      return ServerFailure(message: 'Server error$context: ${error.message}');
    }
    
    // Format errors
    if (error is FormatException) {
      return ServerFailure(message: 'Invalid data format received$context');
    }
    
    // Generic errors
    return ServerFailure(message: 'Unexpected error$context: ${error.toString()}');
  }
  
  /// Handle Supabase Postgrest exceptions
  Failure _handlePostgrestException(PostgrestException error, String context) {
    final message = error.message.toLowerCase();
    final code = error.code;
    
    // Business logic errors
    if (message.contains('insufficient_stock') ||
        message.contains('out_of_stock')) {
      return const ValidationFailure(message: 'Some items are out of stock');
    }

    if (message.contains('delivery_area') ||
        message.contains('service_area')) {
      return const ValidationFailure(message: 'Service not available in your area');
    }

    if (message.contains('minimum_order')) {
      return const ValidationFailure(message: 'Minimum order amount not met');
    }
    
    // Permission errors
    if (code == '42501' || message.contains('permission denied')) {
      return const AuthFailure(message: 'You don\'t have permission for this action');
    }

    // Not found errors
    if (code == '42P01' || message.contains('does not exist')) {
      return const NotFoundFailure(message: 'Requested resource not found');
    }

    // Constraint violations
    if (message.contains('duplicate key') || message.contains('already exists')) {
      return const ValidationFailure(message: 'This item already exists');
    }
    
    // Default server error
    return ServerFailure(message: 'Database error$context. Please try again.');
  }
  
  /// Determine if an error should trigger a retry
  bool _shouldRetryError(dynamic error) {
    // Never retry authentication errors
    if (error is AuthException) return false;
    
    // Never retry validation errors
    if (error is ValidationException) return false;
    
    // Retry network errors
    if (error is SocketException || error is TimeoutException) return true;
    
    // Retry specific HTTP status codes
    if (error is HttpException) {
      final statusCode = int.tryParse(error.message.split(' ').first);
      if (statusCode != null) {
        return NetworkConfig.isRetryableStatusCode(statusCode);
      }
    }
    
    // Retry Supabase server errors but not client errors
    if (error is PostgrestException) {
      final code = error.code;
      // Don't retry client errors (4xx)
      if (code != null && code.startsWith('4')) return false;
      // Retry server errors (5xx) and unknown errors
      return true;
    }
    
    // Default: retry unknown errors
    return true;
  }
}
