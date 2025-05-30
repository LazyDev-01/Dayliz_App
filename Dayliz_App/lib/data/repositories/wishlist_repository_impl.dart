import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_remote_data_source.dart';
import '../datasources/wishlist_local_data_source.dart';
import '../models/product_model.dart';

/// Implementation of [WishlistRepository]
class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;
  final WishlistLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  WishlistRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<WishlistItem>>> getWishlistItems() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItems = await remoteDataSource.getWishlistItems();
        return Right(remoteItems);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final localItems = await localDataSource.getWishlistItems();
        return Right(localItems);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, WishlistItem>> addToWishlist(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItem = await remoteDataSource.addToWishlist(productId);
        await localDataSource.addToWishlist(productId);
        return Right(remoteItem);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final localItem = await localDataSource.addToWishlist(productId);
        return Right(localItem);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> removeFromWishlist(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSuccess = await remoteDataSource.removeFromWishlist(productId);
        await localDataSource.removeFromWishlist(productId);
        return Right(remoteSuccess);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final localSuccess = await localDataSource.removeFromWishlist(productId);
        return Right(localSuccess);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> isInWishlist(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        final isInRemoteWishlist = await remoteDataSource.isInWishlist(productId);
        return Right(isInRemoteWishlist);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final isInLocalWishlist = await localDataSource.isInWishlist(productId);
        return Right(isInLocalWishlist);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> clearWishlist() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSuccess = await remoteDataSource.clearWishlist();
        await localDataSource.clearWishlist();
        return Right(remoteSuccess);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final localSuccess = await localDataSource.clearWishlist();
        return Right(localSuccess);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getWishlistProducts() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProducts = await remoteDataSource.getWishlistProducts();
        await localDataSource.cacheWishlistProducts(remoteProducts);
        return Right(remoteProducts);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final localProducts = await localDataSource.getCachedWishlistProducts();
        return Right(localProducts);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }
} 