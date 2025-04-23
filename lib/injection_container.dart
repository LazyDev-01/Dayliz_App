// Payment Method
sl.registerFactory(() => GetPaymentMethodsUseCase(sl()));
sl.registerFactory(() => AddPaymentMethodUseCase(sl()));
sl.registerFactory(() => SetDefaultPaymentMethodUseCase(sl()));
sl.registerLazySingleton<PaymentMethodRepository>(
  () => PaymentMethodRepositoryImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
    networkInfo: sl(),
  ),
);
sl.registerLazySingleton<PaymentMethodRemoteDataSource>(
  () => PaymentMethodRemoteDataSourceImpl(
    client: sl(),
    baseUrl: sl<String>(instanceName: 'baseUrl'),
  ),
);
sl.registerLazySingleton<PaymentMethodLocalDataSource>(
  () => PaymentMethodLocalDataSourceImpl(
    sharedPreferences: sl(),
  ),
); 