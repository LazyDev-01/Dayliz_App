import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/network_info.dart';
import 'data/datasources/auth_local_data_source.dart';
import 'data/datasources/auth_supabase_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/get_current_user_usecase.dart';
import 'domain/usecases/is_authenticated_usecase.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Use cases
  sl.registerFactory(() => RegisterUseCase(sl()));
  sl.registerFactory(() => LoginUseCase(sl()));
  sl.registerFactory(() => LogoutUseCase(sl()));
  sl.registerFactory(() => GetCurrentUserUseCase(sl()));
  sl.registerFactory(() => IsAuthenticatedUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthSupabaseDataSource(
      supabaseClient: sl(),
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => InternetConnectionChecker());
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Configuration
  sl.registerLazySingleton<String>(
    () => 'https://api.dayliz.com',
    instanceName: 'baseUrl',
  );
}