import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Configuration result for Google Sign-In
class GoogleSignInConfig {
  final bool isConfigured;
  final String? webClientId;
  final String? iosClientId;
  final String? androidClientId;

  GoogleSignInConfig({
    required this.isConfigured,
    this.webClientId,
    this.iosClientId,
    this.androidClientId,
  });
}

/// Configuration result for Deep Link
class DeepLinkConfig {
  final bool isConfigured;
  final String? scheme;
  final String? host;

  DeepLinkConfig({
    required this.isConfigured,
    this.scheme,
    this.host,
  });
}

/// Utility class for testing Google Sign-In configuration
class GoogleSignInTester {
  /// Check if Google Sign-In is properly configured
  static Future<GoogleSignInConfig> checkGoogleSignInConfig() async {
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];
      final androidClientId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];

      final isConfigured = webClientId != null && webClientId.isNotEmpty;

      return GoogleSignInConfig(
        isConfigured: isConfigured,
        webClientId: webClientId,
        iosClientId: iosClientId,
        androidClientId: androidClientId,
      );
    } catch (e) {
      debugPrint('Error checking Google Sign-In config: $e');
      return GoogleSignInConfig(isConfigured: false);
    }
  }

  /// Check if Deep Link is properly configured
  static Future<DeepLinkConfig> checkDeepLinkConfig() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      
      // For a proper implementation, we would check the AndroidManifest.xml and Info.plist
      // But for now, we'll just check if the package name is valid
      final isConfigured = packageName.isNotEmpty && packageName != 'com.example.app';
      
      return DeepLinkConfig(
        isConfigured: isConfigured,
        scheme: '$packageName://',
        host: 'login',
      );
    } catch (e) {
      debugPrint('Error checking Deep Link config: $e');
      return DeepLinkConfig(isConfigured: false);
    }
  }
}
