import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/data/datasources/wishlist_local_data_source.dart';
import 'package:dayliz_app/data/datasources/wishlist_remote_data_source.dart';
import 'package:dayliz_app/data/models/product_model.dart';
import 'package:dayliz_app/data/models/wishlist_item_model.dart';

/// An adapter that implements [WishlistRemoteDataSource] but uses [WishlistLocalDataSource]
/// This allows us to use the local data source as a substitute for the remote data source
/// until the FastAPI backend is ready.
class LocalWishlistAdapter implements WishlistRemoteDataSource {
  final WishlistLocalDataSource localDataSource;

  LocalWishlistAdapter({required this.localDataSource});

  @override
  Future<WishlistItemModel> addToWishlist(String productId) {
    return localDataSource.addToWishlist(productId);
  }

  @override
  Future<bool> clearWishlist() {
    return localDataSource.clearWishlist();
  }

  @override
  Future<List<WishlistItemModel>> getWishlistItems() {
    return localDataSource.getWishlistItems();
  }

  @override
  Future<List<ProductModel>> getWishlistProducts() {
    return localDataSource.getWishlistProducts();
  }

  @override
  Future<bool> isInWishlist(String productId) {
    return localDataSource.isInWishlist(productId);
  }

  @override
  Future<bool> removeFromWishlist(String productId) {
    return localDataSource.removeFromWishlist(productId);
  }
} 