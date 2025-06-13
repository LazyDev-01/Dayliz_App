import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/notification.dart';
import '../models/notification_model.dart';

/// Abstract class for notification remote data source
abstract class NotificationRemoteDataSource {
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
  Future<bool> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    int priority = 0,
  });
  Future<NotificationModel> scheduleNotification({
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
  Future<bool> cancelScheduledNotification(String id);
  Future<NotificationPreferences> getNotificationPreferences(String userId);
  Future<NotificationPreferences> updateNotificationPreferences(NotificationPreferences preferences);
  Future<bool> registerFCMToken(String userId, String token);
  Future<bool> unregisterFCMToken(String userId);
  Future<Map<String, int>> getNotificationStatistics(String userId);
  Future<bool> subscribeToTopic(String userId, String topic);
  Future<bool> unsubscribeFromTopic(String userId, String topic);
  Future<List<String>> getSubscribedTopics(String userId);
}

/// Supabase implementation of notification remote data source
class NotificationSupabaseDataSource implements NotificationRemoteDataSource {
  final SupabaseClient client;

  NotificationSupabaseDataSource({required this.client});

  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Getting notifications for user: $userId');

      var query = client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      if (type != null) {
        query = query.eq('type', type);
      }

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query;
      
      return response.map<NotificationModel>((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error getting notifications: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NotificationModel> getNotificationById(String id) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Getting notification by ID: $id');

      final response = await client
          .from('notifications')
          .select()
          .eq('id', id)
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error getting notification by ID: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Marking notification as read: $id');

      final response = await client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error marking notification as read: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<NotificationModel>> markMultipleAsRead(List<String> ids) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Marking multiple notifications as read: ${ids.length}');

      final response = await client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .in_('id', ids)
          .select();

      return response.map<NotificationModel>((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error marking multiple notifications as read: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> markAllAsRead(String userId) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Marking all notifications as read for user: $userId');

      await client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error marking all notifications as read: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteNotification(String id) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Deleting notification: $id');

      await client
          .from('notifications')
          .delete()
          .eq('id', id);

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error deleting notification: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteMultipleNotifications(List<String> ids) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Deleting multiple notifications: ${ids.length}');

      await client
          .from('notifications')
          .delete()
          .in_('id', ids);

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error deleting multiple notifications: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> clearAllNotifications(String userId) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Clearing all notifications for user: $userId');

      await client
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error clearing all notifications: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Getting unread count for user: $userId');

      final response = await client
          .from('notifications')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.count ?? 0;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error getting unread count: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    int priority = 0,
  }) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Sending push notification to user: $userId');

      // First, create notification record
      await client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'image_url': imageUrl,
        'action_url': actionUrl,
        'priority': priority,
        'is_delivered': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Then call edge function to send push notification
      await client.functions.invoke('send-push-notification', body: {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
        'priority': priority,
      });

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error sending push notification: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NotificationModel> scheduleNotification({
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
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Scheduling notification for user: $userId');

      final response = await client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'image_url': imageUrl,
        'action_url': actionUrl,
        'priority': priority,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_delivered': false,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error scheduling notification: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> cancelScheduledNotification(String id) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Cancelling scheduled notification: $id');

      await client
          .from('notifications')
          .delete()
          .eq('id', id)
          .is_('scheduled_at', null);

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error cancelling scheduled notification: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences(String userId) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Getting notification preferences for user: $userId');

      final response = await client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences
        final defaultPrefs = NotificationPreferences(
          userId: userId,
          updatedAt: DateTime.now(),
        );
        
        await client.from('notification_preferences').insert({
          'user_id': userId,
          'push_notifications_enabled': defaultPrefs.pushNotificationsEnabled,
          'email_notifications_enabled': defaultPrefs.emailNotificationsEnabled,
          'order_updates_enabled': defaultPrefs.orderUpdatesEnabled,
          'promotional_notifications_enabled': defaultPrefs.promotionalNotificationsEnabled,
          'system_announcements_enabled': defaultPrefs.systemAnnouncementsEnabled,
          'sound_enabled': defaultPrefs.soundEnabled,
          'vibration_enabled': defaultPrefs.vibrationEnabled,
          'quiet_hours_start': defaultPrefs.quietHoursStart,
          'quiet_hours_end': defaultPrefs.quietHoursEnd,
          'updated_at': defaultPrefs.updatedAt.toIso8601String(),
        });

        return defaultPrefs;
      }

      return NotificationPreferences(
        userId: response['user_id'],
        pushNotificationsEnabled: response['push_notifications_enabled'] ?? true,
        emailNotificationsEnabled: response['email_notifications_enabled'] ?? true,
        orderUpdatesEnabled: response['order_updates_enabled'] ?? true,
        promotionalNotificationsEnabled: response['promotional_notifications_enabled'] ?? false,
        systemAnnouncementsEnabled: response['system_announcements_enabled'] ?? true,
        soundEnabled: response['sound_enabled'] ?? true,
        vibrationEnabled: response['vibration_enabled'] ?? true,
        quietHoursStart: response['quiet_hours_start'] ?? '22:00',
        quietHoursEnd: response['quiet_hours_end'] ?? '08:00',
        updatedAt: DateTime.parse(response['updated_at']),
      );
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error getting notification preferences: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(NotificationPreferences preferences) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Updating notification preferences for user: ${preferences.userId}');

      final response = await client
          .from('notification_preferences')
          .upsert({
            'user_id': preferences.userId,
            'push_notifications_enabled': preferences.pushNotificationsEnabled,
            'email_notifications_enabled': preferences.emailNotificationsEnabled,
            'order_updates_enabled': preferences.orderUpdatesEnabled,
            'promotional_notifications_enabled': preferences.promotionalNotificationsEnabled,
            'system_announcements_enabled': preferences.systemAnnouncementsEnabled,
            'sound_enabled': preferences.soundEnabled,
            'vibration_enabled': preferences.vibrationEnabled,
            'quiet_hours_start': preferences.quietHoursStart,
            'quiet_hours_end': preferences.quietHoursEnd,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return NotificationPreferences(
        userId: response['user_id'],
        pushNotificationsEnabled: response['push_notifications_enabled'],
        emailNotificationsEnabled: response['email_notifications_enabled'],
        orderUpdatesEnabled: response['order_updates_enabled'],
        promotionalNotificationsEnabled: response['promotional_notifications_enabled'],
        systemAnnouncementsEnabled: response['system_announcements_enabled'],
        soundEnabled: response['sound_enabled'],
        vibrationEnabled: response['vibration_enabled'],
        quietHoursStart: response['quiet_hours_start'],
        quietHoursEnd: response['quiet_hours_end'],
        updatedAt: DateTime.parse(response['updated_at']),
      );
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error updating notification preferences: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> registerFCMToken(String userId, String token) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Registering FCM token for user: $userId');

      await client.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': 'android', // You might want to detect this
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error registering FCM token: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> unregisterFCMToken(String userId) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Unregistering FCM token for user: $userId');

      await client
          .from('user_fcm_tokens')
          .update({'is_active': false})
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error unregistering FCM token: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, int>> getNotificationStatistics(String userId) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Getting notification statistics for user: $userId');

      final response = await client.rpc('get_notification_statistics', params: {
        'user_id_param': userId,
      });

      return Map<String, int>.from(response);
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error getting notification statistics: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> subscribeToTopic(String userId, String topic) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Subscribing user to topic: $userId -> $topic');

      await client.from('user_notification_topics').upsert({
        'user_id': userId,
        'topic': topic,
        'is_subscribed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error subscribing to topic: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> unsubscribeFromTopic(String userId, String topic) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Unsubscribing user from topic: $userId -> $topic');

      await client
          .from('user_notification_topics')
          .update({'is_subscribed': false})
          .eq('user_id', userId)
          .eq('topic', topic);

      return true;
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error unsubscribing from topic: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<String>> getSubscribedTopics(String userId) async {
    try {
      debugPrint('🔔 [NotificationSupabaseDataSource] Getting subscribed topics for user: $userId');

      final response = await client
          .from('user_notification_topics')
          .select('topic')
          .eq('user_id', userId)
          .eq('is_subscribed', true);

      return response.map<String>((item) => item['topic'] as String).toList();
    } catch (e) {
      debugPrint('❌ [NotificationSupabaseDataSource] Error getting subscribed topics: $e');
      throw ServerException(message: e.toString());
    }
  }
}
