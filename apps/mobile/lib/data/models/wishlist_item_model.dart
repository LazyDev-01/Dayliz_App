import '../../domain/entities/wishlist_item.dart';

/// WishlistItemModel class extending WishlistItem entity for data layer operations
class WishlistItemModel extends WishlistItem {
  const WishlistItemModel({
    required String id,
    required String productId,
    required DateTime dateAdded,
  }) : super(
          id: id,
          productId: productId,
          dateAdded: dateAdded,
        );

  /// Create a WishlistItemModel from a WishlistItem entity
  factory WishlistItemModel.fromWishlistItem(WishlistItem wishlistItem) {
    return WishlistItemModel(
      id: wishlistItem.id,
      productId: wishlistItem.productId,
      dateAdded: wishlistItem.dateAdded,
    );
  }

  /// Create a WishlistItemModel from a JSON map
  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'],
      productId: json['product_id'],
      dateAdded: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Convert WishlistItemModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'created_at': dateAdded.toIso8601String(),
    };
  }
} 