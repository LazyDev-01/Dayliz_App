import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/order.dart' as domain;
import '../../domain/entities/order_item.dart' as domain;
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_data_source.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

/// Implementation of the OrderRepository that uses both remote and local data sources
/// Updated to use the new database functions for improved performance
class OrderRepositoryImpl implements OrderRepository {
  final OrderDataSource remoteDataSource;
  final OrderDataSource localDataSource;
  final NetworkInfo networkInfo;
  final SupabaseClient supabaseClient;

  OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.supabaseClient,
  });

  /// Get all orders for the current user
  /// Uses the new get_user_orders database function
  @override
  Future<Either<Failure, List<domain.Order>>> getOrders() async {
    if (await networkInfo.isConnected) {
      try {
        // Use the database function to get orders with details in a single query
        final result = await supabaseClient.rpc('get_user_orders');
        
        if (result.error != null) {
          // If the database function fails, fall back to the standard implementation
          return _getOrdersStandard();
        }
        
        final orders = (result.data as List).map((item) {
          return OrderModel(
            id: item['order_id'],
            orderNumber: item['order_number'],
            userId: item['user_id'] ?? '',
            status: item['status'],
            createdAt: DateTime.parse(item['created_at']),
            updatedAt: item['updated_at'] != null 
                ? DateTime.parse(item['updated_at']) 
                : DateTime.parse(item['created_at']),
            totalAmount: item['total_amount'] != null 
                ? double.parse(item['total_amount'].toString()) 
                : 0.0,
            subtotal: item['subtotal'] != null 
                ? double.parse(item['subtotal'].toString()) 
                : 0.0,
            tax: item['tax'] != null 
                ? double.parse(item['tax'].toString()) 
                : 0.0,
            shipping: item['shipping'] != null 
                ? double.parse(item['shipping'].toString()) 
                : 0.0,
            discount: item['discount'] != null 
                ? double.parse(item['discount'].toString()) 
                : 0.0,
            paymentMethodId: item['payment_method_id'],
            paymentStatus: item['payment_status'] ?? 'pending',
            deliveryAddressId: item['delivery_address_id'],
            items: [], // Items will be loaded separately when needed
          );
        }).toList();
        
        // Cache the orders locally
        await localDataSource.cacheOrders(orders);
        
        return Right(orders);
      } on PostgrestException catch (e) {
        debugPrint('Database error in getOrders: ${e.message}');
        // If the database function fails, fall back to the standard implementation
        return _getOrdersStandard();
      } catch (e) {
        debugPrint('Error in getOrders: $e');
        // If any other error occurs, fall back to the standard implementation
        return _getOrdersStandard();
      }
    } else {
      // If offline, use local data source
      try {
        final localOrders = await localDataSource.getCachedOrders();
        return Right(localOrders);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  /// Standard implementation of getOrders as a fallback
  Future<Either<Failure, List<domain.Order>>> _getOrdersStandard() async {
    try {
      final remoteOrders = await remoteDataSource.getOrders();
      await localDataSource.cacheOrders(remoteOrders);
      return Right(remoteOrders);
    } on ServerException catch (e) {
      try {
        final localOrders = await localDataSource.getCachedOrders();
        return Right(localOrders);
      } on CacheException {
        return Left(ServerFailure(message: e.message));
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get an order by its ID
  /// Uses the standard implementation and the new get_order_details function for items
  @override
  Future<Either<Failure, domain.Order>> getOrderById(String orderId) async {
    if (await networkInfo.isConnected) {
      try {
        // Get the order details
        final order = await remoteDataSource.getOrderById(orderId);
        
        // Get the order items using the database function
        final result = await supabaseClient.rpc(
          'get_order_details',
          params: {'order_id_param': orderId},
        );
        
        if (result.error == null) {
          // If the database function succeeds, use its results
          final items = (result.data as List).map((item) {
            return OrderItemModel(
              id: item['order_item_id'],
              orderId: orderId,
              productId: item['product_id'],
              productName: item['product_name'],
              imageUrl: item['image_url'],
              quantity: item['quantity'],
              unitPrice: item['unit_price'] != null 
                  ? double.parse(item['unit_price'].toString()) 
                  : 0.0,
              totalPrice: item['total_price'] != null 
                  ? double.parse(item['total_price'].toString()) 
                  : 0.0,
              options: item['options'] ?? {},
              variantId: item['variant_id'],
              sku: item['sku'],
            );
          }).toList();
          
          // Update the order with the items
          order.items = items;
        } else {
          // If the database function fails, get the items using the standard implementation
          final items = await remoteDataSource.getOrderItems(orderId);
          order.items = items;
        }
        
        // Cache the order locally
        await localDataSource.cacheOrder(order);
        
        return Right(order);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final localOrder = await localDataSource.getCachedOrderById(orderId);
        return Right(localOrder);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  /// Create a new order
  @override
  Future<Either<Failure, domain.Order>> createOrder(domain.Order order) async {
    if (await networkInfo.isConnected) {
      try {
        final createdOrder = await remoteDataSource.createOrder(order);
        await localDataSource.cacheOrder(createdOrder);
        return Right(createdOrder);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Update an order's status
  @override
  Future<Either<Failure, domain.Order>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedOrder = await remoteDataSource.updateOrderStatus(orderId, status);
        await localDataSource.cacheOrder(updatedOrder);
        return Right(updatedOrder);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Cancel an order
  @override
  Future<Either<Failure, bool>> cancelOrder(String orderId) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.cancelOrder(orderId);
        if (success) {
          // Update the cached order status
          try {
            final cachedOrder = await localDataSource.getCachedOrderById(orderId);
            cachedOrder.status = 'cancelled';
            await localDataSource.cacheOrder(cachedOrder);
          } catch (e) {
            // Ignore cache errors
            debugPrint('Error updating cached order: $e');
          }
        }
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Get order items for an order
  @override
  Future<Either<Failure, List<domain.OrderItem>>> getOrderItems(String orderId) async {
    if (await networkInfo.isConnected) {
      try {
        // Use the database function to get order items with details in a single query
        final result = await supabaseClient.rpc(
          'get_order_details',
          params: {'order_id_param': orderId},
        );
        
        if (result.error != null) {
          // If the database function fails, fall back to the standard implementation
          return _getOrderItemsStandard(orderId);
        }
        
        final items = (result.data as List).map((item) {
          return OrderItemModel(
            id: item['order_item_id'],
            orderId: orderId,
            productId: item['product_id'],
            productName: item['product_name'],
            imageUrl: item['image_url'],
            quantity: item['quantity'],
            unitPrice: item['unit_price'] != null 
                ? double.parse(item['unit_price'].toString()) 
                : 0.0,
            totalPrice: item['total_price'] != null 
                ? double.parse(item['total_price'].toString()) 
                : 0.0,
            options: item['options'] ?? {},
            variantId: item['variant_id'],
            sku: item['sku'],
          );
        }).toList();
        
        return Right(items);
      } on PostgrestException catch (e) {
        debugPrint('Database error in getOrderItems: ${e.message}');
        // If the database function fails, fall back to the standard implementation
        return _getOrderItemsStandard(orderId);
      } catch (e) {
        debugPrint('Error in getOrderItems: $e');
        // If any other error occurs, fall back to the standard implementation
        return _getOrderItemsStandard(orderId);
      }
    } else {
      try {
        final localOrder = await localDataSource.getCachedOrderById(orderId);
        return Right(localOrder.items);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  /// Standard implementation of getOrderItems as a fallback
  Future<Either<Failure, List<domain.OrderItem>>> _getOrderItemsStandard(String orderId) async {
    try {
      final remoteItems = await remoteDataSource.getOrderItems(orderId);
      return Right(remoteItems);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
