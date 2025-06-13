import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_notification_service.dart';
import '../../domain/entities/notification.dart';
import '../../domain/usecases/notifications/get_notifications_usecase.dart';

/// State class for notifications
class NotificationState {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? errorMessage;
  final int unreadCount;
  final bool hasMore;
  final int currentPage;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
    this.unreadCount = 0,
    this.hasMore = true,
    this.currentPage = 1,
  });

  NotificationState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? errorMessage,
    int? unreadCount,
    bool? hasMore,
    int? currentPage,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// State class for notification preferences
class NotificationPreferencesState {
  final NotificationPreferences? preferences;
  final bool isLoading;
  final String? errorMessage;

  const NotificationPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationPreferencesState copyWith({
    NotificationPreferences? preferences,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for Firebase notification service
final firebaseNotificationServiceProvider = Provider<FirebaseNotificationService>((ref) {
  return FirebaseNotificationService.instance;
});

/// Provider for notification state
final notificationStateProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

/// Provider for notification preferences state
final notificationPreferencesProvider = StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferencesState>((ref) {
  return NotificationPreferencesNotifier(ref);
});

/// Provider for unread notification count
final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationStateProvider);
  return state.unreadCount;
});

/// Provider for FCM token
final fcmTokenProvider = StreamProvider<String>((ref) {
  final service = ref.watch(firebaseNotificationServiceProvider);
  return service.tokenStream;
});

/// Provider for incoming notifications
final incomingNotificationProvider = StreamProvider<NotificationEntity>((ref) {
  final service = ref.watch(firebaseNotificationServiceProvider);
  return service.notificationStream;
});

/// Notification state notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref ref;

  NotificationNotifier(this.ref) : super(const NotificationState()) {
    _initialize();
  }

  /// Initialize notification system
  Future<void> _initialize() async {
    try {
      // Initialize Firebase notification service
      final service = ref.read(firebaseNotificationServiceProvider);
      if (!service.isInitialized) {
        await service.initialize();
      }

      // Load initial notifications
      await loadNotifications();

      // Listen for incoming notifications
      ref.listen(incomingNotificationProvider, (previous, next) {
        next.when(
          data: (notification) => _handleIncomingNotification(notification),
          loading: () {},
          error: (error, stack) => debugPrint('Error receiving notification: $error'),
        );
      });

      // Listen for FCM token updates
      ref.listen(fcmTokenProvider, (previous, next) {
        next.when(
          data: (token) => _handleTokenUpdate(token),
          loading: () {},
          error: (error, stack) => debugPrint('Error receiving FCM token: $error'),
        );
      });
    } catch (e) {
      debugPrint('Error initializing notification system: $e');
      state = state.copyWith(
        errorMessage: 'Failed to initialize notifications: $e',
        isLoading: false,
      );
    }
  }

  /// Load notifications
  Future<void> loadNotifications({
    bool refresh = false,
    String? type,
    bool? isRead,
  }) async {
    if (refresh) {
      state = state.copyWith(
        notifications: [],
        currentPage: 1,
        hasMore: true,
        clearError: true,
      );
    }

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Implement with actual use case
      // For now, using mock data
      await Future.delayed(const Duration(milliseconds: 500));

      final mockNotifications = _generateMockNotifications();
      
      state = state.copyWith(
        notifications: refresh ? mockNotifications : [...state.notifications, ...mockNotifications],
        isLoading: false,
        unreadCount: mockNotifications.where((n) => !n.isRead).length,
        hasMore: false, // For mock data
      );
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications: $e',
      );
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Implement pagination with actual use case
      await Future.delayed(const Duration(milliseconds: 500));

      // For mock data, just mark as no more
      state = state.copyWith(
        isLoading: false,
        hasMore: false,
      );
    } catch (e) {
      debugPrint('Error loading more notifications: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load more notifications: $e',
      );
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Update local state immediately
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.markAsRead();
        }
        return notification;
      }).toList();

      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );

      // TODO: Implement with actual use case
      // await markNotificationAsReadUseCase(MarkNotificationAsReadParams(notificationId: notificationId));
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      state = state.copyWith(errorMessage: 'Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final updatedNotifications = state.notifications.map((notification) => notification.markAsRead()).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );

      // TODO: Implement with actual use case
      // await markAllNotificationsAsReadUseCase(NoParams());
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      state = state.copyWith(errorMessage: 'Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );

      // TODO: Implement with actual use case
      // await deleteNotificationUseCase(DeleteNotificationParams(notificationId: notificationId));
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      state = state.copyWith(errorMessage: 'Failed to delete notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      state = state.copyWith(
        notifications: [],
        unreadCount: 0,
      );

      // TODO: Implement with actual use case
      // await clearAllNotificationsUseCase(NoParams());
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
      state = state.copyWith(errorMessage: 'Failed to clear all notifications: $e');
    }
  }

  /// Handle incoming notification
  void _handleIncomingNotification(NotificationEntity notification) {
    debugPrint('🔔 [NotificationNotifier] Handling incoming notification: ${notification.title}');

    // Add to the beginning of the list
    final updatedNotifications = [notification, ...state.notifications];
    final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: newUnreadCount,
    );
  }

  /// Handle FCM token update
  void _handleTokenUpdate(String token) {
    debugPrint('🔔 [NotificationNotifier] FCM token updated: $token');
    
    // TODO: Register token with backend
    // registerFCMTokenUseCase(RegisterFCMTokenParams(token: token));
  }

  /// Generate mock notifications for testing
  List<NotificationEntity> _generateMockNotifications() {
    return [
      NotificationEntity(
        id: '1',
        userId: 'user1',
        title: 'Order Delivered!',
        body: 'Your order DLZ-20250609-0011 has been delivered successfully.',
        type: NotificationEntity.typeOrderDelivered,
        data: {'orderId': 'DLZ-20250609-0011'},
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        priority: NotificationEntity.priorityHigh,
      ),
      NotificationEntity(
        id: '2',
        userId: 'user1',
        title: 'Order Out for Delivery',
        body: 'Your order DLZ-20250609-0010 is out for delivery.',
        type: NotificationEntity.typeOrderOutForDelivery,
        data: {'orderId': 'DLZ-20250609-0010'},
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        priority: NotificationEntity.priorityNormal,
      ),
      NotificationEntity(
        id: '3',
        userId: 'user1',
        title: 'Special Offer!',
        body: 'Get 20% off on your next order. Use code SAVE20.',
        type: NotificationEntity.typePromotion,
        data: {'couponCode': 'SAVE20'},
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        readAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        priority: NotificationEntity.priorityLow,
      ),
    ];
  }
}

/// Notification preferences state notifier
class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferencesState> {
  final Ref ref;

  NotificationPreferencesNotifier(this.ref) : super(const NotificationPreferencesState()) {
    loadPreferences();
  }

  /// Load notification preferences
  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Implement with actual use case
      // For now, using mock data
      await Future.delayed(const Duration(milliseconds: 500));

      final mockPreferences = NotificationPreferences(
        userId: 'user1',
        pushNotificationsEnabled: true,
        emailNotificationsEnabled: true,
        orderUpdatesEnabled: true,
        promotionalNotificationsEnabled: false,
        systemAnnouncementsEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '08:00',
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        preferences: mockPreferences,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notification preferences: $e',
      );
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Implement with actual use case
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update notification preferences: $e',
      );
    }
  }
}
