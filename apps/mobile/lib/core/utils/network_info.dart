import 'package:internet_connection_checker/internet_connection_checker.dart';

/// Interface for checking network connectivity
abstract class NetworkInfo {
  /// Returns true if the device has an active internet connection
  Future<bool> get isConnected;
}

/// Implementation of NetworkInfo interface using InternetConnectionChecker
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  const NetworkInfoImpl({
    required this.connectionChecker,
  });

  /// Returns true if the device has an active internet connection
  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
} 