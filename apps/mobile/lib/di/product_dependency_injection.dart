import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/network_info.dart';
import '../data/datasources/product_local_data_source.dart';
import '../data/datasources/product_remote_data_source.dart';
import '../data/datasources/product_supabase_data_source.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/usecases/get_product_by_id_usecase.dart';
import '../domain/usecases/get_products_by_subcategory_usecase.dart';
import '../domain/usecases/get_products_usecase.dart';
import '../domain/usecases/get_related_products_usecase.dart';
import '../domain/usecases/search_products_usecase.dart';
import 'dependency_injection.dart' show sl;

/// Initialize product-related dependencies with Supabase implementation
Future<void> initProductDependencies() async {
  debugPrint('Initializing product dependencies with Supabase implementation');
  
  // Register data sources if not already registered
  if (!sl.isRegistered<ProductRemoteDataSource>()) {
    sl.registerLazySingleton<ProductRemoteDataSource>(
      () => ProductSupabaseDataSource(
        supabaseClient: Supabase.instance.client,
      ),
    );
    debugPrint('Registered ProductSupabaseDataSource');
  }
  
  if (!sl.isRegistered<ProductLocalDataSource>()) {
    sl.registerLazySingleton<ProductLocalDataSource>(
      () => ProductLocalDataSourceImpl(
        sharedPreferences: sl<SharedPreferences>(),
      ),
    );
    debugPrint('Registered ProductLocalDataSourceImpl');
  }
  
  // Unregister existing repository if it exists
  if (sl.isRegistered<ProductRepository>()) {
    sl.unregister<ProductRepository>();
    debugPrint('Unregistered existing ProductRepository');
  }
  
  // Register the repository with Supabase implementation
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl<ProductRemoteDataSource>(),
      localDataSource: sl<ProductLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  debugPrint('Registered ProductRepositoryImpl with Supabase implementation');
  
  // Register use cases if not already registered
  if (!sl.isRegistered<GetProductsUseCase>()) {
    sl.registerLazySingleton(() => GetProductsUseCase(sl()));
    debugPrint('Registered GetProductsUseCase');
  }
  
  if (!sl.isRegistered<GetProductByIdUseCase>()) {
    sl.registerLazySingleton(() => GetProductByIdUseCase(sl()));
    debugPrint('Registered GetProductByIdUseCase');
  }
  
  if (!sl.isRegistered<GetProductsBySubcategoryUseCase>()) {
    sl.registerLazySingleton(() => GetProductsBySubcategoryUseCase(sl()));
    debugPrint('Registered GetProductsBySubcategoryUseCase');
  }
  
  if (!sl.isRegistered<GetRelatedProductsUseCase>()) {
    sl.registerLazySingleton(() => GetRelatedProductsUseCase(sl()));
    debugPrint('Registered GetRelatedProductsUseCase');
  }
  
  if (!sl.isRegistered<SearchProductsUseCase>()) {
    sl.registerLazySingleton(() => SearchProductsUseCase(sl()));
    debugPrint('Registered SearchProductsUseCase');
  }
  
  debugPrint('Product dependencies initialization completed');
}
