import 'package:equatable/equatable.dart';

/// Domain entity representing a promotional banner
class Banner extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? actionUrl;
  final BannerActionType actionType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Banner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.actionUrl,
    this.actionType = BannerActionType.none,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if banner is currently valid (within date range and active)
  bool get isValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    return true;
  }

  /// Check if banner is expired
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Check if banner is not yet started
  bool get isNotStarted {
    if (startDate == null) return false;
    return DateTime.now().isBefore(startDate!);
  }

  /// Check if banner is currently active and within date range
  bool get isCurrentlyActive {
    return isActive && isValid;
  }

  /// Get banner status as string
  String get status {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    if (isNotStarted) return 'Scheduled';
    return 'Active';
  }

  /// Create a copy with updated fields
  Banner copyWith({
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
    return Banner(
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

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        imageUrl,
        actionUrl,
        actionType,
        startDate,
        endDate,
        isActive,
        displayOrder,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Banner(id: $id, title: $title, actionType: $actionType, isActive: $isActive)';
  }
}

/// Enum representing different types of banner actions
enum BannerActionType {
  /// Navigate to a specific product
  product,
  
  /// Navigate to a category page
  category,
  
  /// Navigate to a product collection
  collection,
  
  /// Navigate to a custom URL
  url,
  
  /// No action (display only)
  none,
}

/// Extension to get display names for banner action types
extension BannerActionTypeExtension on BannerActionType {
  String get displayName {
    switch (this) {
      case BannerActionType.product:
        return 'Product';
      case BannerActionType.category:
        return 'Category';
      case BannerActionType.collection:
        return 'Collection';
      case BannerActionType.url:
        return 'Custom URL';
      case BannerActionType.none:
        return 'No Action';
    }
  }

  String get description {
    switch (this) {
      case BannerActionType.product:
        return 'Navigate to a specific product page';
      case BannerActionType.category:
        return 'Navigate to a category listing';
      case BannerActionType.collection:
        return 'Navigate to a product collection';
      case BannerActionType.url:
        return 'Navigate to a custom URL';
      case BannerActionType.none:
        return 'Display only, no navigation';
    }
  }
}
