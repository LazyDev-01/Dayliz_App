import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/notification.dart';
import '../models/notification_model.dart';

/// Abstract class for notification local data source
abstract class NotificationLocalDataSource {
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  });

  Future<NotificationModel> getNotificationById(String id);
  Future<NotificationModel> markAsRead(String id);
  Future<List<NotificationModel>> markMultipleAsRead(List<String> ids);
  Future<bool> markAllAsRead(String userId);
  Future<bool> deleteNotification(String id);
  Future<bool> deleteMultipleNotifications(List<String> ids);
  Future<bool> clearAllNotifications(String userId);
  Future<int> getUnreadCount(String userId);
  Future<void> cacheNotification(NotificationModel notification);
  Future<void> cacheNotifications(List<NotificationModel> notifications);
  Future<void> cacheUnreadCount(String userId, int count);
  Future<NotificationPreferences> getNotificationPreferences(String userId);
  Future<void> cacheNotificationPreferences(NotificationPreferences preferences);
}

/// SharedPreferences implementation of notification local data source
class NotificationSharedPrefsDataSource implements NotificationLocalDataSource {
  final SharedPreferences sharedPreferences;

  NotificationSharedPrefsDataSource({required this.sharedPreferences});

  static const String _notificationsKey = 'CACHED_NOTIFICATIONS';
  static const String _unreadCountKey = 'CACHED_UNREAD_COUNT';
  static const String _preferencesKey = 'CACHED_NOTIFICATION_PREFERENCES';

  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Getting cached notifications for user: $userId');

      final notificationsJson = sharedPreferences.getString('${_notificationsKey}_$userId');
      if (notificationsJson == null) {
        throw CacheException(message: 'No cached notifications found');
      }

      final List<dynamic> notificationsList = jsonDecode(notificationsJson);
      var notifications = notificationsList
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      // Apply filters
      if (type != null) {
        notifications = notifications.where((n) => n.type == type).toList();
      }

      if (isRead != null) {
        notifications = notifications.where((n) => n.isRead == isRead).toList();
      }

      // Apply pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      if (startIndex >= notifications.length) {
        return [];
      }

      final paginatedNotifications = notifications.sublist(
        startIndex,
        endIndex > notifications.length ? notifications.length : endIndex,
      );

      return paginatedNotifications;
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error getting cached notifications: $e');
      throw CacheException(message: 'Failed to get cached notifications');
    }
  }

  @override
  Future<NotificationModel> getNotificationById(String id) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Getting cached notification by ID: $id');

      // We need to search through all user notifications
      // This is not ideal, but works for the cache implementation
      final keys = sharedPreferences.getKeys()
          .where((key) => key.startsWith(_notificationsKey))
          .toList();

      for (final key in keys) {
        final notificationsJson = sharedPreferences.getString(key);
        if (notificationsJson != null) {
          final List<dynamic> notificationsList = jsonDecode(notificationsJson);
          final notifications = notificationsList
              .map((json) => NotificationModel.fromJson(json))
              .toList();

          final notification = notifications.firstWhere(
            (n) => n.id == id,
            orElse: () => throw CacheException(message: 'Notification not found in cache'),
          );

          return notification;
        }
      }

      throw CacheException(message: 'Notification not found in cache');
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error getting cached notification by ID: $e');
      throw CacheException(message: 'Failed to get cached notification');
    }
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Marking cached notification as read: $id');

      // Find and update the notification
      final keys = sharedPreferences.getKeys()
          .where((key) => key.startsWith(_notificationsKey))
          .toList();

      for (final key in keys) {
        final notificationsJson = sharedPreferences.getString(key);
        if (notificationsJson != null) {
          final List<dynamic> notificationsList = jsonDecode(notificationsJson);
          var notifications = notificationsList
              .map((json) => NotificationModel.fromJson(json))
              .toList();

          final index = notifications.indexWhere((n) => n.id == id);
          if (index != -1) {
            final updatedNotification = notifications[index].copyWithModel(
              isRead: true,
              readAt: DateTime.now(),
            );
            notifications[index] = updatedNotification;

            // Save back to cache
            final updatedJson = jsonEncode(notifications.map((n) => n.toJson()).toList());
            await sharedPreferences.setString(key, updatedJson);

            return updatedNotification;
          }
        }
      }

      throw CacheException(message: 'Notification not found in cache');
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error marking notification as read: $e');
      throw CacheException(message: 'Failed to mark notification as read');
    }
  }

  @override
  Future<List<NotificationModel>> markMultipleAsRead(List<String> ids) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Marking multiple notifications as read: ${ids.length}');

      final updatedNotifications = <NotificationModel>[];

      for (final id in ids) {
        try {
          final notification = await markAsRead(id);
          updatedNotifications.add(notification);
        } catch (e) {
          debugPrint('❌ [NotificationLocalDataSource] Error marking notification $id as read: $e');
        }
      }

      return updatedNotifications;
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error marking multiple notifications as read: $e');
      throw CacheException(message: 'Failed to mark multiple notifications as read');
    }
  }

  @override
  Future<bool> markAllAsRead(String userId) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Marking all notifications as read for user: $userId');

      final notificationsJson = sharedPreferences.getString('${_notificationsKey}_$userId');
      if (notificationsJson == null) {
        return true; // No notifications to mark
      }

      final List<dynamic> notificationsList = jsonDecode(notificationsJson);
      final notifications = notificationsList
          .map((json) => NotificationModel.fromJson(json))
          .map((n) => n.copyWithModel(isRead: true, readAt: DateTime.now()))
          .toList();

      final updatedJson = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await sharedPreferences.setString('${_notificationsKey}_$userId', updatedJson);

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error marking all notifications as read: $e');
      throw CacheException(message: 'Failed to mark all notifications as read');
    }
  }

  @override
  Future<bool> deleteNotification(String id) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Deleting cached notification: $id');

      final keys = sharedPreferences.getKeys()
          .where((key) => key.startsWith(_notificationsKey))
          .toList();

      for (final key in keys) {
        final notificationsJson = sharedPreferences.getString(key);
        if (notificationsJson != null) {
          final List<dynamic> notificationsList = jsonDecode(notificationsJson);
          var notifications = notificationsList
              .map((json) => NotificationModel.fromJson(json))
              .toList();

          final originalLength = notifications.length;
          notifications.removeWhere((n) => n.id == id);

          if (notifications.length != originalLength) {
            // Notification was found and removed
            final updatedJson = jsonEncode(notifications.map((n) => n.toJson()).toList());
            await sharedPreferences.setString(key, updatedJson);
            return true;
          }
        }
      }

      return true; // Notification not found, consider it deleted
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error deleting notification: $e');
      throw CacheException(message: 'Failed to delete notification');
    }
  }

  @override
  Future<bool> deleteMultipleNotifications(List<String> ids) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Deleting multiple notifications: ${ids.length}');

      for (final id in ids) {
        await deleteNotification(id);
      }

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error deleting multiple notifications: $e');
      throw CacheException(message: 'Failed to delete multiple notifications');
    }
  }

  @override
  Future<bool> clearAllNotifications(String userId) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Clearing all notifications for user: $userId');

      await sharedPreferences.remove('${_notificationsKey}_$userId');
      await sharedPreferences.remove('${_unreadCountKey}_$userId');

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error clearing all notifications: $e');
      throw CacheException(message: 'Failed to clear all notifications');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Getting cached unread count for user: $userId');

      final count = sharedPreferences.getInt('${_unreadCountKey}_$userId');
      if (count == null) {
        throw CacheException(message: 'No cached unread count found');
      }

      return count;
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error getting cached unread count: $e');
      throw CacheException(message: 'Failed to get cached unread count');
    }
  }

  @override
  Future<void> cacheNotification(NotificationModel notification) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Caching notification: ${notification.id}');

      final userId = notification.userId;
      final notificationsJson = sharedPreferences.getString('${_notificationsKey}_$userId');
      
      List<NotificationModel> notifications = [];
      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        notifications = notificationsList
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      }

      // Remove existing notification with same ID and add the new one
      notifications.removeWhere((n) => n.id == notification.id);
      notifications.insert(0, notification);

      // Keep only the latest 100 notifications
      if (notifications.length > 100) {
        notifications = notifications.take(100).toList();
      }

      final updatedJson = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await sharedPreferences.setString('${_notificationsKey}_$userId', updatedJson);
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error caching notification: $e');
      throw CacheException(message: 'Failed to cache notification');
    }
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Caching notifications: ${notifications.length}');

      if (notifications.isEmpty) return;

      final userId = notifications.first.userId;
      final notificationsJson = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await sharedPreferences.setString('${_notificationsKey}_$userId', notificationsJson);
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error caching notifications: $e');
      throw CacheException(message: 'Failed to cache notifications');
    }
  }

  @override
  Future<void> cacheUnreadCount(String userId, int count) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Caching unread count for user $userId: $count');

      await sharedPreferences.setInt('${_unreadCountKey}_$userId', count);
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error caching unread count: $e');
      throw CacheException(message: 'Failed to cache unread count');
    }
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences(String userId) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Getting cached notification preferences for user: $userId');

      final preferencesJson = sharedPreferences.getString('${_preferencesKey}_$userId');
      if (preferencesJson == null) {
        throw CacheException(message: 'No cached notification preferences found');
      }

      final Map<String, dynamic> preferencesMap = jsonDecode(preferencesJson);
      return NotificationPreferences(
        userId: preferencesMap['userId'],
        pushNotificationsEnabled: preferencesMap['pushNotificationsEnabled'] ?? true,
        emailNotificationsEnabled: preferencesMap['emailNotificationsEnabled'] ?? true,
        orderUpdatesEnabled: preferencesMap['orderUpdatesEnabled'] ?? true,
        promotionalNotificationsEnabled: preferencesMap['promotionalNotificationsEnabled'] ?? false,
        systemAnnouncementsEnabled: preferencesMap['systemAnnouncementsEnabled'] ?? true,
        soundEnabled: preferencesMap['soundEnabled'] ?? true,
        vibrationEnabled: preferencesMap['vibrationEnabled'] ?? true,
        quietHoursStart: preferencesMap['quietHoursStart'] ?? '22:00',
        quietHoursEnd: preferencesMap['quietHoursEnd'] ?? '08:00',
        updatedAt: DateTime.parse(preferencesMap['updatedAt']),
      );
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error getting cached notification preferences: $e');
      throw CacheException(message: 'Failed to get cached notification preferences');
    }
  }

  @override
  Future<void> cacheNotificationPreferences(NotificationPreferences preferences) async {
    try {
      debugPrint('🔔 [NotificationLocalDataSource] Caching notification preferences for user: ${preferences.userId}');

      final preferencesMap = {
        'userId': preferences.userId,
        'pushNotificationsEnabled': preferences.pushNotificationsEnabled,
        'emailNotificationsEnabled': preferences.emailNotificationsEnabled,
        'orderUpdatesEnabled': preferences.orderUpdatesEnabled,
        'promotionalNotificationsEnabled': preferences.promotionalNotificationsEnabled,
        'systemAnnouncementsEnabled': preferences.systemAnnouncementsEnabled,
        'soundEnabled': preferences.soundEnabled,
        'vibrationEnabled': preferences.vibrationEnabled,
        'quietHoursStart': preferences.quietHoursStart,
        'quietHoursEnd': preferences.quietHoursEnd,
        'updatedAt': preferences.updatedAt.toIso8601String(),
      };

      final preferencesJson = jsonEncode(preferencesMap);
      await sharedPreferences.setString('${_preferencesKey}_${preferences.userId}', preferencesJson);
    } catch (e) {
      debugPrint('❌ [NotificationLocalDataSource] Error caching notification preferences: $e');
      throw CacheException(message: 'Failed to cache notification preferences');
    }
  }
}
