import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/notification.dart';

/// Repository interface for notification-related operations
abstract class NotificationRepository {
  /// Get all notifications for the current user
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  });

  /// Get notification by ID
  Future<Either<Failure, NotificationEntity>> getNotificationById(String id);

  /// Mark notification as read
  Future<Either<Failure, NotificationEntity>> markAsRead(String id);

  /// Mark multiple notifications as read
  Future<Either<Failure, List<NotificationEntity>>> markMultipleAsRead(List<String> ids);

  /// Mark all notifications as read
  Future<Either<Failure, bool>> markAllAsRead();

  /// Delete notification
  Future<Either<Failure, bool>> deleteNotification(String id);

  /// Delete multiple notifications
  Future<Either<Failure, bool>> deleteMultipleNotifications(List<String> ids);

  /// Clear all notifications
  Future<Either<Failure, bool>> clearAllNotifications();

  /// Get unread notification count
  Future<Either<Failure, int>> getUnreadCount();

  /// Send push notification (for testing/admin)
  Future<Either<Failure, bool>> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    int priority = 0,
  });

  /// Schedule notification
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
  });

  /// Cancel scheduled notification
  Future<Either<Failure, bool>> cancelScheduledNotification(String id);

  /// Get notification preferences
  Future<Either<Failure, NotificationPreferences>> getNotificationPreferences();

  /// Update notification preferences
  Future<Either<Failure, NotificationPreferences>> updateNotificationPreferences(
    NotificationPreferences preferences,
  );

  /// Register FCM token
  Future<Either<Failure, bool>> registerFCMToken(String token);

  /// Unregister FCM token
  Future<Either<Failure, bool>> unregisterFCMToken();

  /// Get notification statistics
  Future<Either<Failure, Map<String, int>>> getNotificationStatistics();

  /// Subscribe to notification topic
  Future<Either<Failure, bool>> subscribeToTopic(String topic);

  /// Unsubscribe from notification topic
  Future<Either<Failure, bool>> unsubscribeFromTopic(String topic);

  /// Get subscribed topics
  Future<Either<Failure, List<String>>> getSubscribedTopics();
}
