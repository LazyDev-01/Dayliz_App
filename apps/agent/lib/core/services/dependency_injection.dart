import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:business_logic/business_logic.dart' hide AuthService;
import 'auth_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Get Supabase configuration from environment
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Supabase URL or Anon Key not found in .env file');
  }

  // Initialize Supabase with proper configuration (matching mobile app)
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  );

  // Register Supabase client
  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Register services
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<OrderService>(() => OrderService());
}
