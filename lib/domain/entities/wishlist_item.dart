import 'package:equatable/equatable.dart';

/// WishlistItem entity representing an item in a user's wishlist in the domain layer
class WishlistItem extends Equatable {
  final String id;
  final String productId;
  final DateTime dateAdded;

  const WishlistItem({
    required this.id,
    required this.productId,
    required this.dateAdded,
  });

  @override
  List<Object> get props => [id, productId, dateAdded];

  /// Returns a copy of this WishlistItem with the given fields replaced
  WishlistItem copyWith({
    String? id,
    String? productId,
    DateTime? dateAdded,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
} 