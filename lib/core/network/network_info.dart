import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Abstract class defining the contract for network information
abstract class NetworkInfo {
  /// Returns true if the device is connected to the internet
  Future<bool> get isConnected;
}

/// Implementation of [NetworkInfo] using [InternetConnectionChecker]
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker? connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected async {
    // For web platforms, always return true since internet_connection_checker doesn't work in browsers
    if (kIsWeb) {
      return true;
    }
    
    // Only check connection if not on web
    if (connectionChecker != null) {
      return await connectionChecker!.hasConnection;
    }
    
    return true;
  }
}

// A web-specific implementation that always returns true
class WebNetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
} 