import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../../core/network/network_info.dart';
import '../../core/services/connectivity_checker.dart';

/// Network info provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(InternetConnectionChecker());
});

/// Connectivity state notifier that caches network status and prevents flickering
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  Timer? _connectivityTimer;
  StreamSubscription? _connectivitySubscription;

  ConnectivityNotifier() : super(ConnectivityState.unknown()) {
    _initializeConnectivity();
  }

  /// Initialize connectivity monitoring
  void _initializeConnectivity() async {
    // Get initial connectivity state
    await _checkConnectivity();

    // Set up periodic checks (every 30 seconds when app is active)
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  /// Check connectivity and update state
  Future<void> _checkConnectivity() async {
    if (state.isChecking) return; // Prevent multiple simultaneous checks

    state = state.copyWith(isChecking: true);

    try {
      final hasConnection = await ConnectivityChecker.hasConnection(fastMode: true);
      final newState = hasConnection
          ? ConnectivityState.connected()
          : ConnectivityState.disconnected();

      // Only update if state actually changed to prevent unnecessary rebuilds
      if (state.status != newState.status) {
        state = newState;
      } else {
        state = state.copyWith(isChecking: false);
      }
    } catch (e) {
      state = ConnectivityState.disconnected();
    }
  }

  /// Force refresh connectivity (for retry buttons)
  Future<void> refresh() async {
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Connectivity state
class ConnectivityState {
  final ConnectivityStatus status;
  final bool isChecking;
  final DateTime lastChecked;

  const ConnectivityState({
    required this.status,
    this.isChecking = false,
    required this.lastChecked,
  });

  ConnectivityState.unknown()
      : status = ConnectivityStatus.unknown,
        isChecking = false,
        lastChecked = DateTime.now();

  ConnectivityState.connected()
      : status = ConnectivityStatus.connected,
        isChecking = false,
        lastChecked = DateTime.now();

  ConnectivityState.disconnected()
      : status = ConnectivityStatus.disconnected,
        isChecking = false,
        lastChecked = DateTime.now();

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    bool? isChecking,
    DateTime? lastChecked,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      isChecking: isChecking ?? this.isChecking,
      lastChecked: lastChecked ?? DateTime.now(),
    );
  }

  bool get isConnected => status == ConnectivityStatus.connected;
  bool get isDisconnected => status == ConnectivityStatus.disconnected;
  bool get isUnknown => status == ConnectivityStatus.unknown;
}

enum ConnectivityStatus {
  connected,
  disconnected,
  unknown,
}

/// Connectivity provider that prevents flickering
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

/// Convenience provider for just the connection status
final isConnectedProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  // Assume connected if unknown (optimistic approach)
  return connectivity.isConnected || connectivity.isUnknown;
});