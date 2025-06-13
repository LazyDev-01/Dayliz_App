import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_data_source.dart';
import '../datasources/notification_remote_data_source.dart';
import '../models/notification_model.dart';

/// Implementation of [NotificationRepository]
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final remoteNotifications = await remoteDataSource.getNotifications(
          userId: userId,
          page: page,
          limit: limit,
          type: type,
          isRead: isRead,
        );
        
        // Cache notifications locally
        await localDataSource.cacheNotifications(remoteNotifications);
        
        return Right(remoteNotifications);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final localNotifications = await localDataSource.getNotifications(
          userId: userId,
          page: page,
          limit: limit,
          type: type,
          isRead: isRead,
        );
        return Right(localNotifications);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> getNotificationById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final notification = await remoteDataSource.getNotificationById(id);
        await localDataSource.cacheNotification(notification);
        return Right(notification);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final notification = await localDataSource.getNotificationById(id);
        return Right(notification);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> markAsRead(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final notification = await remoteDataSource.markAsRead(id);
        await localDataSource.cacheNotification(notification);
        return Right(notification);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final notification = await localDataSource.markAsRead(id);
        return Right(notification);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> markMultipleAsRead(List<String> ids) async {
    if (await networkInfo.isConnected) {
      try {
        final notifications = await remoteDataSource.markMultipleAsRead(ids);
        await localDataSource.cacheNotifications(notifications);
        return Right(notifications);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final notifications = await localDataSource.markMultipleAsRead(ids);
        return Right(notifications);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> markAllAsRead() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.markAllAsRead(userId);
        await localDataSource.markAllAsRead(userId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final result = await localDataSource.markAllAsRead(userId);
        return Right(result);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> deleteNotification(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteNotification(id);
        await localDataSource.deleteNotification(id);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final result = await localDataSource.deleteNotification(id);
        return Right(result);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> deleteMultipleNotifications(List<String> ids) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteMultipleNotifications(ids);
        await localDataSource.deleteMultipleNotifications(ids);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final result = await localDataSource.deleteMultipleNotifications(ids);
        return Right(result);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> clearAllNotifications() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.clearAllNotifications(userId);
        await localDataSource.clearAllNotifications(userId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final result = await localDataSource.clearAllNotifications(userId);
        return Right(result);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getUnreadCount(userId);
        await localDataSource.cacheUnreadCount(userId, count);
        return Right(count);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final count = await localDataSource.getUnreadCount(userId);
        return Right(count);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    int priority = 0,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.sendPushNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
          imageUrl: imageUrl,
          actionUrl: actionUrl,
          priority: priority,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, NotificationEntity>> scheduleNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required DateTime scheduledAt,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    int priority = 0,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final notification = await remoteDataSource.scheduleNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          scheduledAt: scheduledAt,
          data: data,
          imageUrl: imageUrl,
          actionUrl: actionUrl,
          priority: priority,
        );
        await localDataSource.cacheNotification(notification);
        return Right(notification);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelScheduledNotification(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.cancelScheduledNotification(id);
        await localDataSource.deleteNotification(id);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>> getNotificationPreferences() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final preferences = await remoteDataSource.getNotificationPreferences(userId);
        await localDataSource.cacheNotificationPreferences(preferences);
        return Right(preferences);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final preferences = await localDataSource.getNotificationPreferences(userId);
        return Right(preferences);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedPreferences = await remoteDataSource.updateNotificationPreferences(preferences);
        await localDataSource.cacheNotificationPreferences(updatedPreferences);
        return Right(updatedPreferences);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        await localDataSource.cacheNotificationPreferences(preferences);
        return Right(preferences);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> registerFCMToken(String token) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.registerFCMToken(userId, token);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> unregisterFCMToken() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.unregisterFCMToken(userId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getNotificationStatistics() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getNotificationStatistics(userId);
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> subscribeToTopic(String topic) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.subscribeToTopic(userId, topic);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> unsubscribeFromTopic(String topic) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.unsubscribeFromTopic(userId, topic);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSubscribedTopics() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      return const Left(AuthFailure(message: 'User not authenticated'));
    }

    if (await networkInfo.isConnected) {
      try {
        final topics = await remoteDataSource.getSubscribedTopics(userId);
        return Right(topics);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Get current user ID from authentication service
  Future<String?> _getCurrentUserId() async {
    try {
      // This should be implemented based on your auth service
      // For now, returning null to indicate not authenticated
      return null;
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
      return null;
    }
  }
}
