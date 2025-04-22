import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_info.dart';

/// Network info provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

/// Mock implementation of NetworkInfo
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
} 