import '../../domain/entities/notification.dart';

/// Model class for [NotificationEntity] with additional functionality for the data layer
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    required super.type,
    super.data,
    super.isRead = false,
    super.isDelivered = false,
    required super.createdAt,
    super.readAt,
    super.scheduledAt,
    super.imageUrl,
    super.actionUrl,
    super.priority = 0,
  });

  /// Create NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      isDelivered: json['is_delivered'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      priority: json['priority'] as int? ?? 0,
    );
  }

  /// Convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'is_read': isRead,
      'is_delivered': isDelivered,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'image_url': imageUrl,
      'action_url': actionUrl,
      'priority': priority,
    };
  }

  /// Create NotificationModel from domain entity
  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      body: entity.body,
      type: entity.type,
      data: entity.data,
      isRead: entity.isRead,
      isDelivered: entity.isDelivered,
      createdAt: entity.createdAt,
      readAt: entity.readAt,
      scheduledAt: entity.scheduledAt,
      imageUrl: entity.imageUrl,
      actionUrl: entity.actionUrl,
      priority: entity.priority,
    );
  }

  /// Create a copy with updated fields
  NotificationModel copyWithModel({
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
    return NotificationModel(
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
}
