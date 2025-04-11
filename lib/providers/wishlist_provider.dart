import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model class for wishlist item
class WishlistItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final DateTime dateAdded;
  final double? discountPercentage;
  final double? rating;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.dateAdded,
    this.discountPercentage,
    this.rating,
  });

  // Create a copy of the wishlist item with (optional) new values
  WishlistItem copyWith({
    String? id,
    String? productId,
    String? name,
    double? price,
    String? imageUrl,
    DateTime? dateAdded,
    double? discountPercentage,
    double? rating,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      dateAdded: dateAdded ?? this.dateAdded,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
    );
  }

  // For JSON serialization if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'dateAdded': dateAdded.toIso8601String(),
      'discountPercentage': discountPercentage,
      'rating': rating,
    };
  }

  // From JSON deserialization if needed
  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'],
      productId: json['productId'],
      name: json['name'],
      price: json['price'],
      imageUrl: json['imageUrl'],
      dateAdded: DateTime.parse(json['dateAdded']),
      discountPercentage: json['discountPercentage'],
      rating: json['rating'],
    );
  }
}

// Wishlist state notifier
class WishlistNotifier extends StateNotifier<List<WishlistItem>> {
  WishlistNotifier() : super([]);

  // Add a product to wishlist
  void addToWishlist(WishlistItem item) {
    if (!isInWishlist(item.productId)) {
      state = [...state, item];
    }
  }

  // Remove a product from wishlist by productId
  void removeFromWishlist(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  // Toggle wishlist status (add if not in wishlist, remove if already in wishlist)
  void toggleWishlistItem(WishlistItem item) {
    if (isInWishlist(item.productId)) {
      removeFromWishlist(item.productId);
    } else {
      addToWishlist(item);
    }
  }

  // Check if a product is in the wishlist
  bool isInWishlist(String productId) {
    return state.any((item) => item.productId == productId);
  }

  // Clear the entire wishlist
  void clearWishlist() {
    state = [];
  }

  // Get a wishlist item by productId
  WishlistItem? getItemById(String productId) {
    try {
      return state.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }
}

// Initial mock data for wishlist
final List<WishlistItem> _initialWishlistItems = [
  WishlistItem(
    id: 'wish1',
    productId: '101',
    name: 'Classic Leather Jacket',
    price: 129.99,
    imageUrl: 'assets/images/products/jacket.jpg',
    dateAdded: DateTime.now().subtract(const Duration(days: 2)),
    discountPercentage: 15,
    rating: 4.7,
  ),
  WishlistItem(
    id: 'wish2',
    productId: '102',
    name: 'Wireless Headphones',
    price: 79.99,
    imageUrl: 'assets/images/products/headphones.jpg',
    dateAdded: DateTime.now().subtract(const Duration(days: 3)),
    discountPercentage: 10,
    rating: 4.5,
  ),
  WishlistItem(
    id: 'wish3',
    productId: '103',
    name: 'Smart Watch',
    price: 159.99,
    imageUrl: 'assets/images/products/smartwatch.jpg',
    dateAdded: DateTime.now().subtract(const Duration(days: 5)),
    rating: 4.8,
  ),
];

// Provider for the wishlist
final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<WishlistItem>>((ref) {
  return WishlistNotifier();
});

// Provider to check if a product is in wishlist
final isInWishlistProvider = Provider.family<bool, String>((ref, productId) {
  final wishlistItems = ref.watch(wishlistProvider);
  return wishlistItems.any((item) => item.productId == productId);
}); 