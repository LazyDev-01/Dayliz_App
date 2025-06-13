import 'package:equatable/equatable.dart';

/// Notification entity representing a notification in the domain layer
class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool isDelivered;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? scheduledAt;
  final String? imageUrl;
  final String? actionUrl;
  final int priority;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    this.isDelivered = false,
    required this.createdAt,
    this.readAt,
    this.scheduledAt,
    this.imageUrl,
    this.actionUrl,
    this.priority = 0,
  });

  /// Notification types
  static const String typeOrderPlaced = 'order_placed';
  static const String typeOrderConfirmed = 'order_confirmed';
  static const String typeOrderPreparing = 'order_preparing';
  static const String typeOrderOutForDelivery = 'order_out_for_delivery';
  static const String typeOrderDelivered = 'order_delivered';
  static const String typeOrderCancelled = 'order_cancelled';
  static const String typePaymentSuccess = 'payment_success';
  static const String typePaymentFailed = 'payment_failed';
  static const String typePromotion = 'promotion';
  static const String typeSystemAnnouncement = 'system_announcement';
  static const String typeZoneExpansion = 'zone_expansion';
  static const String typeAccountUpdate = 'account_update';

  /// Priority levels
  static const int priorityLow = 0;
  static const int priorityNormal = 1;
  static const int priorityHigh = 2;
  static const int priorityCritical = 3;

  /// Create a copy with updated fields
  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isDelivered,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? scheduledAt,
    String? imageUrl,
    String? actionUrl,
    int? priority,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      priority: priority ?? this.priority,
    );
  }

  /// Mark notification as read
  NotificationEntity markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Mark notification as delivered
  NotificationEntity markAsDelivered() {
    return copyWith(
      isDelivered: true,
    );
  }

  /// Check if notification is order-related
  bool get isOrderNotification {
    return [
      typeOrderPlaced,
      typeOrderConfirmed,
      typeOrderPreparing,
      typeOrderOutForDelivery,
      typeOrderDelivered,
      typeOrderCancelled,
    ].contains(type);
  }

  /// Check if notification is payment-related
  bool get isPaymentNotification {
    return [
      typePaymentSuccess,
      typePaymentFailed,
    ].contains(type);
  }

  /// Check if notification is promotional
  bool get isPromotionalNotification {
    return type == typePromotion;
  }

  /// Get notification icon based on type
  String get iconName {
    switch (type) {
      case typeOrderPlaced:
      case typeOrderConfirmed:
        return 'receipt';
      case typeOrderPreparing:
        return 'restaurant';
      case typeOrderOutForDelivery:
        return 'delivery_dining';
      case typeOrderDelivered:
        return 'check_circle';
      case typeOrderCancelled:
        return 'cancel';
      case typePaymentSuccess:
        return 'payment';
      case typePaymentFailed:
        return 'error';
      case typePromotion:
        return 'local_offer';
      case typeSystemAnnouncement:
        return 'announcement';
      case typeZoneExpansion:
        return 'location_on';
      case typeAccountUpdate:
        return 'account_circle';
      default:
        return 'notifications';
    }
  }

  /// Get notification color based on type and priority
  String get colorHex {
    if (priority >= priorityCritical) return '#F44336'; // Red
    if (priority >= priorityHigh) return '#FF9800'; // Orange
    
    switch (type) {
      case typeOrderDelivered:
      case typePaymentSuccess:
        return '#4CAF50'; // Green
      case typeOrderCancelled:
      case typePaymentFailed:
        return '#F44336'; // Red
      case typePromotion:
        return '#9C27B0'; // Purple
      case typeZoneExpansion:
        return '#2196F3'; // Blue
      default:
        return '#757575'; // Grey
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        type,
        data,
        isRead,
        isDelivered,
        createdAt,
        readAt,
        scheduledAt,
        imageUrl,
        actionUrl,
        priority,
      ];
}

/// Notification preferences entity
class NotificationPreferences extends Equatable {
  final String userId;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool orderUpdatesEnabled;
  final bool promotionalNotificationsEnabled;
  final bool systemAnnouncementsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final DateTime updatedAt;

  const NotificationPreferences({
    required this.userId,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.orderUpdatesEnabled = true,
    this.promotionalNotificationsEnabled = false,
    this.systemAnnouncementsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  NotificationPreferences copyWith({
    String? userId,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? orderUpdatesEnabled,
    bool? promotionalNotificationsEnabled,
    bool? systemAnnouncementsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      orderUpdatesEnabled: orderUpdatesEnabled ?? this.orderUpdatesEnabled,
      promotionalNotificationsEnabled: promotionalNotificationsEnabled ?? this.promotionalNotificationsEnabled,
      systemAnnouncementsEnabled: systemAnnouncementsEnabled ?? this.systemAnnouncementsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if notifications should be shown based on quiet hours
  bool shouldShowNotification() {
    if (!pushNotificationsEnabled) return false;

    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // Simple time comparison (doesn't handle overnight quiet hours)
    if (quietHoursStart.compareTo(quietHoursEnd) > 0) {
      // Overnight quiet hours (e.g., 22:00 to 08:00)
      return currentTime.compareTo(quietHoursEnd) >= 0 && currentTime.compareTo(quietHoursStart) < 0;
    } else {
      // Same day quiet hours (e.g., 12:00 to 14:00)
      return currentTime.compareTo(quietHoursStart) < 0 || currentTime.compareTo(quietHoursEnd) >= 0;
    }
  }

  @override
  List<Object?> get props => [
        userId,
        pushNotificationsEnabled,
        emailNotificationsEnabled,
        orderUpdatesEnabled,
        promotionalNotificationsEnabled,
        systemAnnouncementsEnabled,
        soundEnabled,
        vibrationEnabled,
        quietHoursStart,
        quietHoursEnd,
        updatedAt,
      ];
}
