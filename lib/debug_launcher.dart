import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/screens/debug/google_sign_in_debug_screen.dart';
import 'package:dayliz_app/services/auth_service.dart';

/// A simple launcher app that directly opens the Google Sign-In debug screen
/// Run this file directly to debug Google Sign-In issues
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase
  try {
    debugPrint('Initializing Supabase with URL: ${dotenv.env['SUPABASE_URL']}');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      debug: true,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }
  
  // Initialize AuthService
  try {
    await AuthService.instance.initialize();
    debugPrint('AuthService initialized successfully');
  } catch (e) {
    debugPrint('Error initializing AuthService: $e');
  }
  
  runApp(const DebugLauncher());
}

class DebugLauncher extends StatelessWidget {
  const DebugLauncher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sign-In Debug',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GoogleSignInDebugScreen(),
    );
  }
}
