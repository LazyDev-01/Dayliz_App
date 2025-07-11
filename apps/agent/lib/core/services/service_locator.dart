import 'package:get_it/get_it.dart';
import 'package:business_logic/business_logic.dart';

/// Service locator for dependency injection
final GetIt sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // Services
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<OrderService>(() => OrderService());

  // Initialize auth service
  await sl<AuthService>().initialize();
}