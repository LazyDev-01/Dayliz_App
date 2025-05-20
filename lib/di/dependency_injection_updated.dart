import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../data/repositories/product_repository_impl_updated.dart';
import '../data/repositories/cart_repository_impl_updated.dart';
import '../data/repositories/user_profile_repository_impl_updated.dart';
import '../data/repositories/order_repository_impl_updated.dart';
import '../data/repositories/wishlist_repository_impl_updated.dart';

import '../domain/repositories/product_repository.dart';
import '../domain/repositories/cart_repository.dart';
import '../domain/repositories/user_profile_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/repositories/wishlist_repository.dart';

import '../data/datasources/product_remote_data_source.dart';
import '../data/datasources/product_local_data_source.dart';
import '../data/datasources/cart_remote_data_source.dart';
import '../data/datasources/cart_local_data_source.dart';
import '../data/datasources/user_profile_data_source.dart';
import '../data/datasources/order_datasource.dart';
import '../data/datasources/wishlist_remote_data_source.dart';
import '../data/datasources/wishlist_local_data_source.dart';

import '../core/network/network_info.dart';

/// Global service locator
final sl = GetIt.instance;

/// Updates the repository implementations to use the new database features
Future<void> updateRepositoryImplementations() async {
  debugPrint('Updating repository implementations to use new database features...');

  try {
    // Unregister existing repositories
    if (sl.isRegistered<ProductRepository>()) {
      sl.unregister<ProductRepository>();
      debugPrint('Unregistered existing ProductRepository');
    }

    if (sl.isRegistered<CartRepository>()) {
      sl.unregister<CartRepository>();
      debugPrint('Unregistered existing CartRepository');
    }

    if (sl.isRegistered<UserProfileRepository>()) {
      sl.unregister<UserProfileRepository>();
      debugPrint('Unregistered existing UserProfileRepository');
    }

    if (sl.isRegistered<OrderRepository>()) {
      sl.unregister<OrderRepository>();
      debugPrint('Unregistered existing OrderRepository');
    }

    if (sl.isRegistered<WishlistRepository>()) {
      sl.unregister<WishlistRepository>();
      debugPrint('Unregistered existing WishlistRepository');
    }

    // Register updated repositories
    
    // Product Repository
    sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(
        remoteDataSource: sl<ProductRemoteDataSource>(),
        localDataSource: sl<ProductLocalDataSource>(),
        networkInfo: sl<NetworkInfo>(),
        supabaseClient: Supabase.instance.client,
      ),
    );
    debugPrint('Registered updated ProductRepository');

    // Cart Repository
    sl.registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(
        remoteDataSource: sl<CartRemoteDataSource>(),
        localDataSource: sl<CartLocalDataSource>(),
        networkInfo: sl<NetworkInfo>(),
        supabaseClient: Supabase.instance.client,
      ),
    );
    debugPrint('Registered updated CartRepository');

    // User Profile Repository
    sl.registerLazySingleton<UserProfileRepository>(
      () => UserProfileRepositoryImpl(
        remoteDataSource: sl.get<UserProfileDataSource>(instanceName: 'remote'),
        localDataSource: sl.get<UserProfileDataSource>(instanceName: 'local'),
        networkInfo: sl<NetworkInfo>(),
        supabaseClient: Supabase.instance.client,
      ),
    );
    debugPrint('Registered updated UserProfileRepository');

    // Order Repository
    sl.registerLazySingleton<OrderRepository>(
      () => OrderRepositoryImpl(
        remoteDataSource: sl.get<OrderDataSource>(instanceName: 'remote'),
        localDataSource: sl.get<OrderDataSource>(instanceName: 'local'),
        networkInfo: sl<NetworkInfo>(),
        supabaseClient: Supabase.instance.client,
      ),
    );
    debugPrint('Registered updated OrderRepository');

    // Wishlist Repository
    sl.registerLazySingleton<WishlistRepository>(
      () => WishlistRepositoryImpl(
        remoteDataSource: sl<WishlistRemoteDataSource>(),
        localDataSource: sl<WishlistLocalDataSource>(),
        networkInfo: sl<NetworkInfo>(),
        supabaseClient: Supabase.instance.client,
      ),
    );
    debugPrint('Registered updated WishlistRepository');

    debugPrint('Repository implementations updated successfully');
  } catch (e) {
    debugPrint('Error updating repository implementations: $e');
  }
}

/// Updates the data sources to use the new database features if needed
Future<void> updateDataSources() async {
  // This function can be used to update data sources if needed in the future
  // For now, we're just using the existing data sources with the updated repositories
  debugPrint('Data sources are already registered and do not need to be updated');
}

/// Main function to update all dependencies
Future<void> updateDependencies() async {
  await updateRepositoryImplementations();
  await updateDataSources();
  debugPrint('All dependencies updated successfully');
}
