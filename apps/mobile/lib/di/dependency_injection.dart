import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/datasources/user_profile_supabase_adapter.dart';

import '../core/network/network_info.dart';
import '../domain/repositories/auth_repository.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../domain/usecases/get_current_user_usecase.dart';
import '../domain/usecases/is_authenticated_usecase.dart';
import '../domain/usecases/forgot_password_usecase.dart';
import '../domain/usecases/sign_in_with_google_usecase.dart';
import '../domain/usecases/reset_password_usecase.dart';
import '../domain/usecases/change_password_usecase.dart';
import '../domain/usecases/check_email_exists_usecase.dart';
import '../core/services/supabase_service.dart';

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
import '../data/datasources/category_remote_data_source.dart';
import '../data/datasources/category_supabase_data_source.dart';


import '../data/datasources/auth_data_source.dart';
import '../data/datasources/auth_supabase_data_source_new.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../core/config/app_config.dart';

import '../domain/repositories/user_profile_repository.dart';
import '../data/repositories/user_profile_repository_impl.dart';

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
import '../data/apis/storage_file_api.dart' as app_storage;
// Order imports
import '../domain/repositories/order_repository.dart';
import '../data/repositories/order_repository_impl.dart';
import '../data/datasources/order_data_source.dart';
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
import '../data/datasources/wishlist_local_adapter.dart';
import '../domain/usecases/get_wishlist_items_usecase.dart';
import '../domain/usecases/add_to_wishlist_usecase.dart';
import '../domain/usecases/remove_from_wishlist_usecase.dart';
import '../domain/usecases/is_in_wishlist_usecase.dart';
import '../domain/usecases/clear_wishlist_usecase.dart';
import '../domain/usecases/get_wishlist_products_usecase.dart';
import '../data/datasources/cart_data_source_factory.dart' show CartDataSourceFactory;
import '../domain/repositories/payment_method_repository.dart';
import '../data/repositories/payment_method_repository_impl.dart';
import '../data/datasources/payment_method_remote_data_source.dart';
import '../data/datasources/payment_method_local_data_source.dart';
import '../domain/usecases/payment_method/get_payment_methods_usecase.dart';
import '../domain/usecases/payment_method/add_payment_method_usecase.dart';
import '../domain/usecases/payment_method/set_default_payment_method_usecase.dart';

// Location and Zone imports
import '../domain/repositories/location_repository.dart';
import '../domain/repositories/zone_repository.dart';
import '../data/repositories/location_repository_impl.dart';
import '../data/repositories/zone_repository_impl.dart';
import '../data/datasources/location_local_data_source.dart';
import '../data/datasources/zone_remote_data_source.dart';
import '../domain/usecases/location/request_location_permission_usecase.dart';
import '../domain/usecases/location/get_current_location_usecase.dart';
import '../domain/usecases/location/validate_delivery_zone_usecase.dart';
import '../domain/usecases/location/location_setup_usecase.dart';

/// Global service locator for clean architecture components
final sl = GetIt.instance;

/// Initializes clean architecture components with minimal dependencies
/// to avoid conflicts with existing code.
Future<void> initCleanArchitecture() async {
  // Core - Register NetworkInfo only if not already registered
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerLazySingleton<NetworkInfo>(() {
      // For web platforms, use the web-specific implementation that always returns true
      if (kIsWeb) {
        return WebNetworkInfoImpl();
      }
      // For other platforms, use the regular implementation
      return NetworkInfoImpl(sl());
    });
  }

  // External - Register http.Client only if not already registered
  if (!sl.isRegistered<http.Client>()) {
    sl.registerLazySingleton(() => http.Client());
  }

  // Only register InternetConnectionChecker for non-web platforms and if not already registered
  if (!kIsWeb && !sl.isRegistered<InternetConnectionChecker>()) {
    sl.registerLazySingleton(() => InternetConnectionChecker());
  }

  // Register SharedPreferences only if not already registered
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => sharedPreferences);
  }

  // Register Supabase client only if not already registered
  if (!sl.isRegistered<SupabaseClient>()) {
    try {
      sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
      debugPrint('SupabaseClient registered in GetIt successfully');
    } catch (e) {
      debugPrint('Error registering SupabaseClient in GetIt: $e');
      // If Supabase is not initialized yet, we'll handle this later
    }
  }

  // Register SupabaseService for clean architecture only if not already registered
  if (!sl.isRegistered<SupabaseService>()) {
    sl.registerLazySingleton<SupabaseService>(() => SupabaseService.instance);
  }

  // Initialize app configuration
  await AppConfig.init();

  //-------------------------------------------------------------------------
  // Authentication
  //-------------------------------------------------------------------------

  // Auth Data Sources - Direct Supabase registration
  if (!sl.isRegistered<AuthDataSource>(instanceName: 'remote')) {
    sl.registerLazySingleton<AuthDataSource>(
      () => AuthSupabaseDataSource(supabaseClient: sl<SupabaseClient>()),
      instanceName: 'remote',
    );
  }

  if (!sl.isRegistered<AuthDataSource>(instanceName: 'local')) {
    sl.registerLazySingleton<AuthDataSource>(
      () => AuthLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
      instanceName: 'local',
    );
  }

  // Auth Repository
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: sl.get<AuthDataSource>(instanceName: 'remote'),
        localDataSource: sl.get<AuthDataSource>(instanceName: 'local'),
        networkInfo: sl(),
      ),
    );
  }

  // Auth Use Cases
  if (!sl.isRegistered<LoginUseCase>()) {
    sl.registerLazySingleton(() => LoginUseCase(sl()));
  }
  if (!sl.isRegistered<RegisterUseCase>()) {
    sl.registerLazySingleton(() => RegisterUseCase(sl()));
  }
  if (!sl.isRegistered<LogoutUseCase>()) {
    sl.registerLazySingleton(() => LogoutUseCase(sl()));
  }
  if (!sl.isRegistered<GetCurrentUserUseCase>()) {
    sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  }
  if (!sl.isRegistered<IsAuthenticatedUseCase>()) {
    sl.registerLazySingleton(() => IsAuthenticatedUseCase(sl()));
  }
  if (!sl.isRegistered<ForgotPasswordUseCase>()) {
    sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  }
  if (!sl.isRegistered<SignInWithGoogleUseCase>()) {
    sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  }
  if (!sl.isRegistered<ResetPasswordUseCase>()) {
    sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  }
  if (!sl.isRegistered<ChangePasswordUseCase>()) {
    sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  }
  if (!sl.isRegistered<CheckEmailExistsUseCase>()) {
    sl.registerLazySingleton(() => CheckEmailExistsUseCase(sl()));
  }

  //-------------------------------------------------------------------------
  // Product
  //-------------------------------------------------------------------------

  // Product dependencies will be initialized by product_dependency_injection.dart
  // This ensures we use real Supabase data instead of mock data

  //-------------------------------------------------------------------------
  // Category
  //-------------------------------------------------------------------------

  // Register Category Remote Data Source (Supabase) only if not already registered
  if (!sl.isRegistered<CategoryRemoteDataSource>()) {
    sl.registerLazySingleton<CategoryRemoteDataSource>(
      () => CategorySupabaseDataSource(supabaseClient: sl()),
    );
  }

  // Register Category Repository with Supabase implementation only if not already registered
  if (!sl.isRegistered<CategoryRepository>()) {
    sl.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(
        networkInfo: sl(),
        remoteDataSource: sl(), // Use Supabase data source
      ),
    );
  }

  // Register Category Use Cases only if not already registered
  if (!sl.isRegistered<GetCategoriesUseCase>()) {
    sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  }
  if (!sl.isRegistered<GetCategoriesWithSubcategoriesUseCase>()) {
    sl.registerLazySingleton(() => GetCategoriesWithSubcategoriesUseCase(sl()));
  }
  if (!sl.isRegistered<GetCategoryByIdUseCase>()) {
    sl.registerLazySingleton(() => GetCategoryByIdUseCase(sl()));
  }
  if (!sl.isRegistered<GetSubcategoriesUseCase>()) {
    sl.registerLazySingleton(() => GetSubcategoriesUseCase(sl()));
  }

  //-------------------------------------------------------------------------
  // Cart
  //-------------------------------------------------------------------------

  // Register cart data sources
  if (!sl.isRegistered<CartRemoteDataSource>()) {
    sl.registerLazySingleton<CartRemoteDataSource>(
      () => CartDataSourceFactory.getActiveDataSource(),
    );
  }

  if (!sl.isRegistered<CartLocalDataSource>()) {
    sl.registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(sharedPreferences: sl()),
    );
  }

  // Cart Repository
  if (!sl.isRegistered<CartRepository>()) {
    sl.registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ),
    );
  }

  // Cart Use Cases
  if (!sl.isRegistered<GetCartItemsUseCase>()) {
    sl.registerLazySingleton(() => GetCartItemsUseCase(sl()));
  }
  if (!sl.isRegistered<AddToCartUseCase>()) {
    sl.registerLazySingleton(() => AddToCartUseCase(sl()));
  }
  if (!sl.isRegistered<RemoveFromCartUseCase>()) {
    sl.registerLazySingleton(() => RemoveFromCartUseCase(sl()));
  }
  if (!sl.isRegistered<UpdateCartQuantityUseCase>()) {
    sl.registerLazySingleton(() => UpdateCartQuantityUseCase(sl()));
  }
  if (!sl.isRegistered<ClearCartUseCase>()) {
    sl.registerLazySingleton(() => ClearCartUseCase(sl()));
  }
  if (!sl.isRegistered<GetCartTotalPriceUseCase>()) {
    sl.registerLazySingleton(() => GetCartTotalPriceUseCase(sl()));
  }
  if (!sl.isRegistered<GetCartItemCountUseCase>()) {
    sl.registerLazySingleton(() => GetCartItemCountUseCase(sl()));
  }
  if (!sl.isRegistered<IsInCartUseCase>()) {
    sl.registerLazySingleton(() => IsInCartUseCase(sl()));
  }

  //-------------------------------------------------------------------------
  // User Profile
  //-------------------------------------------------------------------------

  // User Profile Use cases
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileImageUseCase(sl()));

  // Register UploadProfileImageUseCase with the correct repository
  sl.registerLazySingleton<UploadProfileImageUseCase>(
    () => UploadProfileImageUseCase(sl<UserProfileRepository>())
  );

  sl.registerLazySingleton(() => GetUserAddressesUseCase(sl()));
  sl.registerLazySingleton(() => AddAddressUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAddressUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAddressUseCase(sl()));
  sl.registerLazySingleton(() => SetDefaultAddressUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserPreferencesUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePreferencesUseCase(sl()));

  // API clients
  sl.registerLazySingleton<app_storage.StorageFileApi>(
    () => app_storage.StorageFileApiImpl(),
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
    () => UserProfileSupabaseAdapter(
      client: Supabase.instance.client,
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
  if (!sl.isRegistered<WishlistLocalDataSource>()) {
    sl.registerLazySingleton<WishlistLocalDataSource>(
      () => WishlistLocalDataSourceImpl(sharedPreferences: sl()),
    );
  }

  // Register the WishlistRemoteDataSource using LocalWishlistAdapter
  // This uses local storage until the FastAPI backend is ready
  if (!sl.isRegistered<WishlistRemoteDataSource>()) {
    sl.registerLazySingleton<WishlistRemoteDataSource>(
      () => LocalWishlistAdapter(localDataSource: sl()),
    );
  }

  // Wishlist Repository
  if (!sl.isRegistered<WishlistRepository>()) {
    sl.registerLazySingleton<WishlistRepository>(
      () => WishlistRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ),
    );
  }

  // Wishlist Use Cases
  if (!sl.isRegistered<GetWishlistItemsUseCase>()) {
    sl.registerLazySingleton(() => GetWishlistItemsUseCase(sl()));
  }
  if (!sl.isRegistered<AddToWishlistUseCase>()) {
    sl.registerLazySingleton(() => AddToWishlistUseCase(sl()));
  }
  if (!sl.isRegistered<RemoveFromWishlistUseCase>()) {
    sl.registerLazySingleton(() => RemoveFromWishlistUseCase(sl()));
  }
  if (!sl.isRegistered<IsInWishlistUseCase>()) {
    sl.registerLazySingleton(() => IsInWishlistUseCase(sl()));
  }
  if (!sl.isRegistered<ClearWishlistUseCase>()) {
    sl.registerLazySingleton(() => ClearWishlistUseCase(sl()));
  }
  if (!sl.isRegistered<GetWishlistProductsUseCase>()) {
    sl.registerLazySingleton(() => GetWishlistProductsUseCase(sl()));
  }

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

  // Register Order-related dependencies
  _registerOrderDependencies();

  //-------------------------------------------------------------------------
  // Location and Zone
  //-------------------------------------------------------------------------

  // Zone Data Sources
  if (!sl.isRegistered<ZoneRemoteDataSource>()) {
    sl.registerLazySingleton<ZoneRemoteDataSource>(
      () => ZoneSupabaseRemoteDataSource(client: sl()),
    );
  }

  // Location Data Sources
  if (!sl.isRegistered<LocationLocalDataSource>()) {
    sl.registerLazySingleton<LocationLocalDataSource>(
      () => LocationLocalDataSourceImpl(),
    );
  }

  // Zone Repository
  if (!sl.isRegistered<ZoneRepository>()) {
    sl.registerLazySingleton<ZoneRepository>(
      () => ZoneRepositoryImpl(
        remoteDataSource: sl(),
        networkInfo: sl(),
      ),
    );
  }

  // Location Repository
  if (!sl.isRegistered<LocationRepository>()) {
    sl.registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(
        localDataSource: sl(),
        zoneRepository: sl(),
        networkInfo: sl(),
      ),
    );
  }

  // Location Use Cases
  if (!sl.isRegistered<RequestLocationPermissionUseCase>()) {
    sl.registerLazySingleton(() => RequestLocationPermissionUseCase(sl()));
  }
  if (!sl.isRegistered<CheckLocationPermissionUseCase>()) {
    sl.registerLazySingleton(() => CheckLocationPermissionUseCase(sl()));
  }
  if (!sl.isRegistered<IsLocationServiceEnabledUseCase>()) {
    sl.registerLazySingleton(() => IsLocationServiceEnabledUseCase(sl()));
  }
  if (!sl.isRegistered<GetCurrentLocationUseCase>()) {
    sl.registerLazySingleton(() => GetCurrentLocationUseCase(sl()));
  }
  if (!sl.isRegistered<ValidateDeliveryZoneUseCase>()) {
    sl.registerLazySingleton(() => ValidateDeliveryZoneUseCase(sl()));
  }
  if (!sl.isRegistered<GetLocationAndValidateZoneUseCase>()) {
    sl.registerLazySingleton(() => GetLocationAndValidateZoneUseCase(sl()));
  }
  if (!sl.isRegistered<IsLocationSetupCompletedUseCase>()) {
    sl.registerLazySingleton(() => IsLocationSetupCompletedUseCase(sl()));
  }
  if (!sl.isRegistered<MarkLocationSetupCompletedUseCase>()) {
    sl.registerLazySingleton(() => MarkLocationSetupCompletedUseCase(sl()));
  }
  if (!sl.isRegistered<ClearLocationSetupStatusUseCase>()) {
    sl.registerLazySingleton(() => ClearLocationSetupStatusUseCase(sl()));
  }

  debugPrint('Clean architecture component registration complete');
}

/// Register order-related dependencies
void _registerOrderDependencies() {
  try {
    // Register OrderRepository if not already registered
    if (!sl.isRegistered<OrderRepository>()) {
      // Register OrderRemoteDataSource if not already registered
      if (!sl.isRegistered<OrderRemoteDataSource>()) {
        sl.registerLazySingleton<OrderRemoteDataSource>(
          () => OrderRemoteDataSource(
            client: sl(),
            baseUrl: AppConfig.useFastAPI ?
              AppConfig.fastApiBaseUrl :
              AppConfig.supabaseUrl,
          ),
        );
      }

      // Register OrderLocalDataSource if not already registered
      if (!sl.isRegistered<OrderLocalDataSource>()) {
        sl.registerLazySingleton<OrderLocalDataSource>(
          () => OrderLocalDataSource(
            sharedPreferences: sl(),
          ),
        );
      }

      // Register OrderRepository
      sl.registerLazySingleton<OrderRepository>(
        () => OrderRepositoryImpl(
          remoteDataSource: sl<OrderRemoteDataSource>(),
          localDataSource: sl<OrderLocalDataSource>(),
          networkInfo: sl<NetworkInfo>(),
        ),
      );
    }

    // Register Order Use Cases
    if (!sl.isRegistered<GetOrdersUseCase>()) {
      sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
    }

    if (!sl.isRegistered<GetOrderByIdUseCase>()) {
      sl.registerLazySingleton(() => GetOrderByIdUseCase(sl()));
    }

    if (!sl.isRegistered<CreateOrderUseCase>()) {
      sl.registerLazySingleton(() => CreateOrderUseCase(sl()));
    }

    if (!sl.isRegistered<GetOrdersByStatusUseCase>()) {
      sl.registerLazySingleton(() => GetOrdersByStatusUseCase(sl()));
    }

    if (!sl.isRegistered<CancelOrderUseCase>()) {
      sl.registerLazySingleton(() => CancelOrderUseCase(sl()));
    }

    debugPrint('Order dependencies registered successfully');
  } catch (e) {
    debugPrint('Error registering order dependencies: $e');
    // Don't rethrow to avoid breaking the initialization process
  }
}

/// Initialize authentication components separately
Future<void> initAuthentication() async {
  debugPrint('Initializing authentication components...');

  try {
    // Initialize Supabase if not already initialized
    try {
      // Just access the client to see if it's initialized
      Supabase.instance.client;
      debugPrint('Supabase already initialized, using existing client');
    } catch (e) {
      // Supabase not initialized yet, initialize it
      final supabaseUrl = AppConfig.supabaseUrl;
      final supabaseAnonKey = AppConfig.supabaseAnonKey;

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Supabase URL or Anon Key not found in configuration');
      }

      debugPrint('Supabase not initialized yet, initializing now');
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true,
      );
      debugPrint('Supabase.initialize completed successfully');
    }

    // Register Supabase client if not already registered
    if (!sl.isRegistered<SupabaseClient>()) {
      sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
      debugPrint('SupabaseClient registered in GetIt successfully');
    }

    // Register SupabaseService for clean architecture if not already registered
    if (!sl.isRegistered<SupabaseService>()) {
      sl.registerLazySingleton<SupabaseService>(() => SupabaseService.instance);
      debugPrint('SupabaseService registered in GetIt for clean architecture');
    }

    // Initialize auth data sources and repository if not already registered
    if (!sl.isRegistered<AuthDataSource>(instanceName: 'remote')) {
      sl.registerLazySingleton<AuthDataSource>(
        () => AuthSupabaseDataSource(supabaseClient: sl<SupabaseClient>()),
        instanceName: 'remote',
      );
    }

    if (!sl.isRegistered<AuthDataSource>(instanceName: 'local')) {
      sl.registerLazySingleton<AuthDataSource>(
        () => AuthLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
        instanceName: 'local',
      );
    }

    if (!sl.isRegistered<AuthRepository>()) {
      sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          remoteDataSource: sl.get<AuthDataSource>(instanceName: 'remote'),
          localDataSource: sl.get<AuthDataSource>(instanceName: 'local'),
          networkInfo: sl(),
        ),
      );
    }

    // Register auth use cases if not already registered
    if (!sl.isRegistered<LoginUseCase>()) {
      sl.registerLazySingleton(() => LoginUseCase(sl()));
    }

    if (!sl.isRegistered<RegisterUseCase>()) {
      sl.registerLazySingleton(() => RegisterUseCase(sl()));
    }

    if (!sl.isRegistered<LogoutUseCase>()) {
      sl.registerLazySingleton(() => LogoutUseCase(sl()));
    }

    if (!sl.isRegistered<GetCurrentUserUseCase>()) {
      sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
    }

    if (!sl.isRegistered<IsAuthenticatedUseCase>()) {
      sl.registerLazySingleton(() => IsAuthenticatedUseCase(sl()));
    }

    if (!sl.isRegistered<ForgotPasswordUseCase>()) {
      sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
    }

    if (!sl.isRegistered<SignInWithGoogleUseCase>()) {
      sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
    }

    if (!sl.isRegistered<ResetPasswordUseCase>()) {
      sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
    }

    if (!sl.isRegistered<ChangePasswordUseCase>()) {
      sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
    }

    if (!sl.isRegistered<CheckEmailExistsUseCase>()) {
      sl.registerLazySingleton(() => CheckEmailExistsUseCase(sl()));
    }

    // Initialize cart components if not already registered
    if (!sl.isRegistered<CartRemoteDataSource>()) {
      sl.registerLazySingleton<CartRemoteDataSource>(
        () => CartDataSourceFactory.getActiveDataSource(),
      );
    }

    if (!sl.isRegistered<CartLocalDataSource>()) {
      sl.registerLazySingleton<CartLocalDataSource>(
        () => CartLocalDataSourceImpl(sharedPreferences: sl()),
      );
    }

    if (!sl.isRegistered<CartRepository>()) {
      sl.registerLazySingleton<CartRepository>(
        () => CartRepositoryImpl(
          remoteDataSource: sl(),
          localDataSource: sl(),
          networkInfo: sl(),
        ),
      );
    }

    // Cart Use Cases
    if (!sl.isRegistered<GetCartItemsUseCase>()) {
      sl.registerLazySingleton(() => GetCartItemsUseCase(sl()));
    }

    if (!sl.isRegistered<AddToCartUseCase>()) {
      sl.registerLazySingleton(() => AddToCartUseCase(sl()));
    }

    if (!sl.isRegistered<RemoveFromCartUseCase>()) {
      sl.registerLazySingleton(() => RemoveFromCartUseCase(sl()));
    }

    if (!sl.isRegistered<UpdateCartQuantityUseCase>()) {
      sl.registerLazySingleton(() => UpdateCartQuantityUseCase(sl()));
    }

    if (!sl.isRegistered<ClearCartUseCase>()) {
      sl.registerLazySingleton(() => ClearCartUseCase(sl()));
    }

    if (!sl.isRegistered<GetCartTotalPriceUseCase>()) {
      sl.registerLazySingleton(() => GetCartTotalPriceUseCase(sl()));
    }

    if (!sl.isRegistered<GetCartItemCountUseCase>()) {
      sl.registerLazySingleton(() => GetCartItemCountUseCase(sl()));
    }

    if (!sl.isRegistered<IsInCartUseCase>()) {
      sl.registerLazySingleton(() => IsInCartUseCase(sl()));
    }

    debugPrint('Authentication and cart components initialized successfully');
    return;
  } catch (e) {
    debugPrint('Error initializing authentication components: $e');
    rethrow;
  }
}

/// Reinitialize authentication dependencies when the backend is changed
Future<void> reInitializeAuthDependencies() async {
  // Unregister existing dependencies
  sl.unregister<AuthDataSource>(instanceName: 'remote');
  sl.unregister<AuthDataSource>(instanceName: 'local');
  sl.unregister<AuthRepository>();

  // Re-register with direct Supabase registration
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthSupabaseDataSource(supabaseClient: sl<SupabaseClient>()),
    instanceName: 'remote',
  );

  sl.registerLazySingleton<AuthDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl<SharedPreferences>()),
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