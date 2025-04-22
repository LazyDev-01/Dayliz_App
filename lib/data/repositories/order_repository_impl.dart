import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/order.dart' as domain;
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_datasource.dart';
import '../models/order_model.dart';

/// Implementation of the OrderRepository that uses both remote and local data sources
class OrderRepositoryImpl implements OrderRepository {
  final OrderDataSource remoteDataSource;
  final OrderDataSource localDataSource;
  final NetworkInfo networkInfo;

  OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  /// Get all orders for the current user
  @override
  Future<Either<Failure, List<domain.Order>>> getOrders() async {
    return await _getOrders(() => remoteDataSource.getOrders());
  }

  /// Get an order by its ID
  @override
  Future<Either<Failure, domain.Order>> getOrderById(String orderId) async {
    return await _getOrder(() => remoteDataSource.getOrderById(orderId));
  }

  /// Create a new order
  @override
  Future<Either<Failure, domain.Order>> createOrder(domain.Order order) async {
    if (await networkInfo.isConnected) {
      try {
        final OrderModel orderModel = order is OrderModel
            ? order
            : OrderModel(
                id: order.id,
                userId: order.userId,
                items: order.items,
                subtotal: order.subtotal,
                tax: order.tax,
                shipping: order.shipping,
                total: order.total,
                status: order.status,
                createdAt: order.createdAt,
                updatedAt: order.updatedAt,
                shippingAddress: order.shippingAddress,
                billingAddress: order.billingAddress,
                paymentMethod: order.paymentMethod,
                trackingNumber: order.trackingNumber,
                notes: order.notes,
                couponCode: order.couponCode,
                discount: order.discount,
              );

        final remoteOrder = await remoteDataSource.createOrder(orderModel);
        try {
          // Cache the newly created order
          await localDataSource.createOrder(remoteOrder);
        } catch (_) {
          // If caching fails, we can still proceed with the remote order
        }
        return Right(remoteOrder);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Cancel an order
  @override
  Future<Either<Failure, bool>> cancelOrder(String orderId, {String? reason}) async {
    if (await networkInfo.isConnected) {
      try {
        final bool success = await remoteDataSource.cancelOrder(orderId, reason: reason);
        if (success) {
          try {
            // Update local cache with the cancelled order
            await localDataSource.cancelOrder(orderId, reason: reason);
          } catch (_) {
            // If updating local cache fails, we can still proceed
          }
        }
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Track an order's shipping status
  @override
  Future<Either<Failure, Map<String, dynamic>>> trackOrder(String orderId) async {
    if (await networkInfo.isConnected) {
      try {
        final trackingInfo = await remoteDataSource.trackOrder(orderId);
        return Right(trackingInfo);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection. Tracking requires an internet connection.'));
    }
  }

  /// Get order statistics for the current user (counts by status)
  @override
  Future<Either<Failure, Map<String, int>>> getOrderStatistics() async {
    if (await networkInfo.isConnected) {
      try {
        final statistics = await remoteDataSource.getOrderStatistics();
        try {
          // Cache the statistics for offline use
          await _cacheOrderStatistics(statistics);
        } catch (_) {
          // If caching fails, we can still proceed
        }
        return Right(statistics);
      } on ServerException catch (e) {
        // Try to get cached statistics if server fails
        try {
          final cachedStats = await localDataSource.getOrderStatistics();
          return Right(cachedStats);
        } catch (_) {
          return Left(ServerFailure(message: e.message));
        }
      }
    } else {
      // Try to get cached statistics if offline
      try {
        final cachedStats = await localDataSource.getOrderStatistics();
        return Right(cachedStats);
      } catch (e) {
        if (e is CacheException) {
          return Left(CacheFailure(message: e.message));
        }
        return Left(NetworkFailure(message: 'No internet connection and no cached data available'));
      }
    }
  }

  /// Get orders by status
  @override
  Future<Either<Failure, List<domain.Order>>> getOrdersByStatus(String status) async {
    return await _getOrders(() => remoteDataSource.getOrdersByStatus(status));
  }

  /// Search orders by query
  @override
  Future<Either<Failure, List<domain.Order>>> searchOrders(String query) async {
    return await _getOrders(() => remoteDataSource.searchOrders(query));
  }

  /// Generic method to get orders with caching
  Future<Either<Failure, List<domain.Order>>> _getOrders(
      Future<List<OrderModel>> Function() getOrdersFunction) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteOrders = await getOrdersFunction();
        _cacheOrders(remoteOrders);
        return Right(remoteOrders);
      } on ServerException catch (e) {
        // Try to get from local cache if server fails
        try {
          final localOrders = await localDataSource.getOrders();
          return Right(localOrders);
        } catch (_) {
          return Left(ServerFailure(message: e.message));
        }
      }
    } else {
      // Try to get from local cache if offline
      try {
        final localOrders = await localDataSource.getOrders();
        return Right(localOrders);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  /// Generic method to get a single order with caching
  Future<Either<Failure, domain.Order>> _getOrder(
      Future<OrderModel> Function() getOrderFunction) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteOrder = await getOrderFunction();
        try {
          // Add the order to local cache
          final allOrders = await localDataSource.getOrders();
          final index = allOrders.indexWhere((o) => o.id == remoteOrder.id);
          
          if (index >= 0) {
            // Replace existing order
            allOrders[index] = remoteOrder;
          } else {
            // Add new order
            allOrders.add(remoteOrder);
          }
          
          _cacheOrders(allOrders);
        } catch (_) {
          // If caching fails, we can still proceed
        }
        return Right(remoteOrder);
      } on ServerException catch (e) {
        // Try to get from local cache if server fails
        try {
          final localOrder = await localDataSource.getOrderById(e.message.split(' ').last);
          return Right(localOrder);
        } catch (_) {
          return Left(ServerFailure(message: e.message));
        }
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message));
      }
    } else {
      // Try to get from local cache if offline
      try {
        final localOrder = await localDataSource.getOrderById(
            // Extract the order ID from the function being called
            getOrderFunction.toString().split('(').last.split(')').first,
        );
        return Right(localOrder);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message));
      }
    }
  }

  /// Cache a list of orders in the local data source
  Future<void> _cacheOrders(List<OrderModel> orders) async {
    try {
      await (localDataSource as dynamic).cacheOrders(orders);
    } catch (_) {
      // Silently fail if caching is not supported or fails
    }
  }

  /// Cache order statistics in the local data source
  Future<void> _cacheOrderStatistics(Map<String, int> statistics) async {
    try {
      await (localDataSource as dynamic)._cacheOrderStatistics(statistics);
    } catch (_) {
      // Silently fail if caching is not supported or fails
    }
  }
} 