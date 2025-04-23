import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/network/network_info.dart';
import '../domain/repositories/auth_repository.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../services/auth_service.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../domain/usecases/get_current_user_usecase.dart';
import '../domain/usecases/is_authenticated_usecase.dart';
import '../domain/usecases/forgot_password_usecase.dart';
import '../domain/usecases/sign_in_with_google_usecase.dart';
import '../domain/repositories/product_repository.dart';
import '../data/repositories/product_repository_impl.dart';
import '../data/datasources/product_remote_data_source.dart';
import '../data/datasources/product_local_data_source.dart';
import '../domain/usecases/get_products_usecase.dart';
import '../domain/usecases/get_product_by_id_usecase.dart';
import '../domain/usecases/get_related_products_usecase.dart';
import '../services/product_service.dart';
import '../domain/repositories/cart_repository.dart';
import '../data/repositories/cart_repository_impl.dart';
import '../data/datasources/cart_remote_data_source.dart';
import '../data/datasources/cart_local_data_source.dart';
import '../domain/usecases/get_cart_items_usecase.dart';
import '../domain/usecases/add_to_cart_usecase.dart';
import '../domain/usecases/remove_from_cart_usecase.dart';
import '../domain/usecases/update_cart_quantity_usecase.dart';
import '../domain/usecases/clear_cart_usecase.dart';
import '../domain/usecases/get_cart_total_price_usecase.dart';
import '../domain/usecases/get_cart_item_count_usecase.dart';
import '../domain/usecases/is_in_cart_usecase.dart';
// Category imports
import '../domain/repositories/category_repository.dart';
import '../data/repositories/category_repository_impl.dart';
import '../domain/usecases/get_categories_usecase.dart';
import '../domain/usecases/get_categories_with_subcategories_usecase.dart';
import '../domain/usecases/get_category_by_id_usecase.dart';
import '../domain/usecases/get_subcategories_usecase.dart';
import '../domain/usecases/get_products_by_subcategory_usecase.dart';
import '../data/datasources/auth_data_source.dart';
import '../data/datasources/auth_data_source_factory.dart';
import '../core/config/app_config.dart' show AppConfig;
import '../data/datasources/auth_data_source_factory.dart' show BackendType;
import '../domain/repositories/user_profile_repository.dart';
import '../data/repositories/user_profile_repository_impl.dart';
import '../data/datasources/user_profile_remote_data_source.dart';
import '../data/datasources/user_profile_local_data_source.dart';
import '../domain/usecases/get_user_profile_usecase.dart';
import '../domain/usecases/update_user_profile_usecase.dart';
import '../domain/usecases/upload_profile_image_usecase.dart';
import '../domain/usecases/user_profile/get_user_addresses_usecase.dart';
import '../domain/usecases/user_profile/add_address_usecase.dart';
import '../domain/usecases/user_profile/update_address_usecase.dart';
import '../domain/usecases/user_profile/delete_address_usecase.dart';
import '../domain/usecases/user_profile/set_default_address_usecase.dart';
import '../domain/usecases/update_preferences_usecase.dart';
import '../data/datasources/user_profile_data_source.dart';
import '../domain/usecases/user_profile/update_profile_image_usecase.dart';
import '../domain/usecases/user_profile/update_user_preferences_usecase.dart';
import '../data/apis/storage_file_api.dart';
// Order imports
import '../domain/repositories/order_repository.dart';
import '../data/repositories/order_repository_impl.dart';
import '../data/datasources/order_datasource.dart';
import '../data/datasources/order_remote_data_source.dart';
import '../data/datasources/order_local_data_source.dart';
import '../domain/usecases/orders/get_orders_usecase.dart';
import '../domain/usecases/orders/get_order_by_id_usecase.dart';
import '../domain/usecases/orders/get_orders_by_status_usecase.dart';
import '../domain/usecases/orders/cancel_order_usecase.dart';
import '../domain/usecases/orders/create_order_usecase.dart';
import '../domain/usecases/orders/track_order_usecase.dart';
// Wishlist imports
import '../domain/repositories/wishlist_repository.dart';
import '../data/repositories/wishlist_repository_impl.dart';
import '../data/datasources/wishlist_remote_data_source.dart';
import '../data/datasources/wishlist_local_data_source.dart';
import '../domain/usecases/get_wishlist_items_usecase.dart';
import '../domain/usecases/add_to_wishlist_usecase.dart';
import '../domain/usecases/remove_from_wishlist_usecase.dart';
import '../domain/usecases/is_in_wishlist_usecase.dart';
import '../domain/usecases/clear_wishlist_usecase.dart';
import '../domain/usecases/get_wishlist_products_usecase.dart';
import '../data/datasources/wishlist_local_adapter.dart';
import '../data/datasources/cart_data_source_factory.dart' show CartDataSourceFactory;
import '../domain/repositories/payment_method_repository.dart';
import '../data/repositories/payment_method_repository_impl.dart';
import '../data/datasources/payment_method_remote_data_source.dart';
import '../data/datasources/payment_method_local_data_source.dart';
import '../domain/usecases/payment_method/get_payment_methods_usecase.dart';
import '../domain/usecases/payment_method/add_payment_method_usecase.dart';
import '../domain/usecases/payment_method/set_default_payment_method_usecase.dart';

/// Global service locator for clean architecture components
final sl = GetIt.instance;

/// Initializes clean architecture components with minimal dependencies
/// to avoid conflicts with existing code.
Future<void> initCleanArchitecture() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() {
    // For web platforms, use the web-specific implementation that always returns true
    if (kIsWeb) {
      return WebNetworkInfoImpl();
    }
    // For other platforms, use the regular implementation
    return NetworkInfoImpl(sl());
  });

  // External
  sl.registerLazySingleton(() => http.Client());

  // Only register InternetConnectionChecker for non-web platforms
  if (!kIsWeb) {
    sl.registerLazySingleton(() => InternetConnectionChecker());
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Services - Use existing instances for backward compatibility
  sl.registerLazySingleton(() => AuthService.instance);
  sl.registerLazySingleton(() => ProductService());

  // Initialize app configuration
  await AppConfig.init();

  //-------------------------------------------------------------------------
  // Authentication
  //-------------------------------------------------------------------------

  // Auth Data Sources - Using a factory for backend flexibility
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceFactory.getActiveDataSource(),
    instanceName: 'remote',
  );

  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceFactory.getDataSource(BackendType.supabase),
    instanceName: 'local',
  );

  // Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl.get<AuthDataSource>(instanceName: 'remote'),
      localDataSource: sl.get<AuthDataSource>(instanceName: 'local'),
      networkInfo: sl(),
    ),
  );

  // Auth Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => IsAuthenticatedUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));

  //-------------------------------------------------------------------------
  // Product
  //-------------------------------------------------------------------------

  // Product Data Sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Product Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Product Use Cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetProductsBySubcategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetRelatedProductsUseCase(sl()));

  //-------------------------------------------------------------------------
  // Category
  //-------------------------------------------------------------------------

  // Register Category Repository with mock implementation
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      networkInfo: sl(),
      remoteDataSource: null, // Use mock data for now
    ),
  );

  // Register Category Use Cases
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesWithSubcategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoryByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetSubcategoriesUseCase(sl()));

  //-------------------------------------------------------------------------
  // Cart
  //-------------------------------------------------------------------------

  // Register cart data sources
  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartDataSourceFactory.getActiveDataSource(),
  );

  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Cart Repository
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Cart Use Cases
  sl.registerLazySingleton(() => GetCartItemsUseCase(sl()));
  sl.registerLazySingleton(() => AddToCartUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFromCartUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCartQuantityUseCase(sl()));
  sl.registerLazySingleton(() => ClearCartUseCase(sl()));
  sl.registerLazySingleton(() => GetCartTotalPriceUseCase(sl()));
  sl.registerLazySingleton(() => GetCartItemCountUseCase(sl()));
  sl.registerLazySingleton(() => IsInCartUseCase(sl()));

  //-------------------------------------------------------------------------
  // User Profile
  //-------------------------------------------------------------------------

  // User Profile Use cases
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileImageUseCase(sl()));
  sl.registerLazySingleton(() => UploadProfileImageUseCase(sl()));
  sl.registerLazySingleton(() => GetUserAddressesUseCase(sl()));
  sl.registerLazySingleton(() => AddAddressUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAddressUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAddressUseCase(sl()));
  sl.registerLazySingleton(() => SetDefaultAddressUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePreferencesUseCase(sl()));

  // API clients
  sl.registerLazySingleton<StorageFileApi>(
    () => StorageFileApiImpl(),
  );

  // Repository
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(
      remoteDataSource: sl.get<UserProfileDataSource>(instanceName: 'remote'),
      localDataSource: sl.get<UserProfileDataSource>(instanceName: 'local'),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<UserProfileDataSource>(
    () => UserProfileRemoteDataSource(
      client: sl(),
      storageFileApi: sl(),
      baseUrl: 'https://api.dayliz.com/v1',
    ),
    instanceName: 'remote',
  );

  sl.registerLazySingleton<UserProfileDataSource>(
    () => UserProfileLocalDataSource(sharedPreferences: sl()),
    instanceName: 'local',
  );

  //-------------------------------------------------------------------------
  // Orders
  //-------------------------------------------------------------------------

  // Order Data Sources
  sl.registerLazySingleton<OrderDataSource>(
    () => OrderRemoteDataSource(client: sl()),
    instanceName: 'remote',
  );

  sl.registerLazySingleton<OrderDataSource>(
    () => OrderLocalDataSource(sharedPreferences: sl()),
    instanceName: 'local',
  );

  // Order Repository
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(
      remoteDataSource: sl.get<OrderDataSource>(instanceName: 'remote'),
      localDataSource: sl.get<OrderDataSource>(instanceName: 'local'),
      networkInfo: sl(),
    ),
  );

  // Order Use Cases
  sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
  sl.registerLazySingleton(() => GetOrderByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetOrdersByStatusUseCase(sl()));
  sl.registerLazySingleton(() => CancelOrderUseCase(sl()));
  sl.registerLazySingleton(() => CreateOrderUseCase(sl()));
  sl.registerLazySingleton(() => TrackOrderUseCase(sl()));

  //-------------------------------------------------------------------------
  // Wishlist
  //-------------------------------------------------------------------------

  // Wishlist Data Sources
  sl.registerLazySingleton<WishlistLocalDataSource>(
    () => WishlistLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Register the WishlistRemoteDataSource with our adapter
  sl.registerLazySingleton<WishlistRemoteDataSource>(
    () => LocalWishlistAdapter(localDataSource: sl()),
  );

  // Wishlist Repository
  sl.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Wishlist Use Cases
  sl.registerLazySingleton(() => GetWishlistItemsUseCase(sl()));
  sl.registerLazySingleton(() => AddToWishlistUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFromWishlistUseCase(sl()));
  sl.registerLazySingleton(() => IsInWishlistUseCase(sl()));
  sl.registerLazySingleton(() => ClearWishlistUseCase(sl()));
  sl.registerLazySingleton(() => GetWishlistProductsUseCase(sl()));

  //-------------------------------------------------------------------------
  // Payment Methods
  //-------------------------------------------------------------------------

  // Register Payment Method Data Sources
  sl.registerLazySingleton<PaymentMethodRemoteDataSource>(
    () => PaymentMethodRemoteDataSourceImpl(
      client: sl(),
      baseUrl: AppConfig.useFastAPI ?
        AppConfig.fastApiBaseUrl :
        AppConfig.supabaseUrl,
    ),
  );

  sl.registerLazySingleton<PaymentMethodLocalDataSource>(
    () => PaymentMethodLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  // Register Payment Method Repository
  sl.registerLazySingleton<PaymentMethodRepository>(
    () => PaymentMethodRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Register Payment Method Use Cases
  sl.registerLazySingleton(() => GetPaymentMethodsUseCase(sl()));
  sl.registerLazySingleton(() => AddPaymentMethodUseCase(sl()));
  sl.registerLazySingleton(() => SetDefaultPaymentMethodUseCase(sl()));

  print('Clean architecture component registration complete');
}

/// Reinitialize authentication dependencies when the backend is changed
Future<void> reInitializeAuthDependencies() async {
  // Unregister existing dependencies
  sl.unregister<AuthDataSource>(instanceName: 'remote');
  sl.unregister<AuthDataSource>(instanceName: 'local');
  sl.unregister<AuthRepository>();

  // Re-register with new backend selection
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceFactory.getActiveDataSource(),
    instanceName: 'remote',
  );

  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceFactory.getDataSource(BackendType.supabase),
    instanceName: 'local',
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl.get<AuthDataSource>(instanceName: 'remote'),
      localDataSource: sl.get<AuthDataSource>(instanceName: 'local'),
      networkInfo: sl(),
    ),
  );
}