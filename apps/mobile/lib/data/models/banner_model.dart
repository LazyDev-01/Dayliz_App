import '../../domain/entities/banner.dart';

/// Data model for Banner entity with JSON serialization
class BannerModel extends Banner {
  const BannerModel({
    required String id,
    required String title,
    required String subtitle,
    required String imageUrl,
    String? actionUrl,
    required BannerActionType actionType,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
    int displayOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          title: title,
          subtitle: subtitle,
          imageUrl: imageUrl,
          actionUrl: actionUrl,
          actionType: actionType,
          startDate: startDate,
          endDate: endDate,
          isActive: isActive,
          displayOrder: displayOrder,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create BannerModel from JSON
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['image_url'] as String,
      actionUrl: json['action_url'] as String?,
      actionType: _parseActionType(json['action_type'] as String?),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert BannerModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'action_type': actionType.toString().split('.').last,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'display_order': displayOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create BannerModel from domain entity
  factory BannerModel.fromEntity(Banner entity) {
    return BannerModel(
      id: entity.id,
      title: entity.title,
      subtitle: entity.subtitle,
      imageUrl: entity.imageUrl,
      actionUrl: entity.actionUrl,
      actionType: entity.actionType,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isActive: entity.isActive,
      displayOrder: entity.displayOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create a copy with updated fields
  BannerModel copyWithModel({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? actionUrl,
    BannerActionType? actionType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionType: actionType ?? this.actionType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parse action type from string
  static BannerActionType _parseActionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'product':
        return BannerActionType.product;
      case 'category':
        return BannerActionType.category;
      case 'collection':
        return BannerActionType.collection;
      case 'url':
        return BannerActionType.url;
      default:
        return BannerActionType.none;
    }
  }

  @override
  String toString() {
    return 'BannerModel(id: $id, title: $title, actionType: $actionType, isActive: $isActive)';
  }
}
