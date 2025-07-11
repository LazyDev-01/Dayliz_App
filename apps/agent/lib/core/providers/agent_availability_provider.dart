import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/agent_availability_service.dart';

/// Agent availability state
class AgentAvailabilityState {
  final String status;
  final int currentOrdersCount;
  final int maxOrdersCapacity;
  final DateTime? lastSeenAt;
  final Map<String, dynamic>? lastLocation;
  final bool isLoading;
  final String? error;

  const AgentAvailabilityState({
    this.status = 'offline',
    this.currentOrdersCount = 0,
    this.maxOrdersCapacity = 3,
    this.lastSeenAt,
    this.lastLocation,
    this.isLoading = false,
    this.error,
  });

  AgentAvailabilityState copyWith({
    String? status,
    int? currentOrdersCount,
    int? maxOrdersCapacity,
    DateTime? lastSeenAt,
    Map<String, dynamic>? lastLocation,
    bool? isLoading,
    String? error,
  }) {
    return AgentAvailabilityState(
      status: status ?? this.status,
      currentOrdersCount: currentOrdersCount ?? this.currentOrdersCount,
      maxOrdersCapacity: maxOrdersCapacity ?? this.maxOrdersCapacity,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastLocation: lastLocation ?? this.lastLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isBusy => status == 'busy';
  bool get isOffline => status == 'offline';
  bool get isOnBreak => status == 'on_break';
  bool get hasCapacity => currentOrdersCount < maxOrdersCapacity;
}

/// Agent availability notifier
class AgentAvailabilityNotifier extends StateNotifier<AgentAvailabilityState> {
  final AgentAvailabilityService _service;
  String? _currentAgentId;

  AgentAvailabilityNotifier(this._service) : super(const AgentAvailabilityState());

  /// Initialize with agent ID
  void setAgentId(String agentId) {
    _currentAgentId = agentId;
    _loadAvailability();
  }

  /// Load current availability status
  Future<void> _loadAvailability() async {
    if (_currentAgentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final availability = await _service.getAgentAvailability(_currentAgentId!);
      
      if (availability != null) {
        state = state.copyWith(
          status: availability['status'] ?? 'offline',
          currentOrdersCount: availability['current_orders_count'] ?? 0,
          maxOrdersCapacity: availability['max_orders_capacity'] ?? 3,
          lastSeenAt: availability['last_seen_at'] != null 
              ? DateTime.parse(availability['last_seen_at']) 
              : null,
          lastLocation: availability['last_location'],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load availability: ${e.toString()}',
      );
    }
  }

  /// Go online and available for orders
  Future<void> goOnline() async {
    if (_currentAgentId == null) return;

    try {
      await _service.goOnline(_currentAgentId!);
      state = state.copyWith(status: 'available');
    } catch (e) {
      state = state.copyWith(error: 'Failed to go online: ${e.toString()}');
    }
  }

  /// Go offline
  Future<void> goOffline() async {
    if (_currentAgentId == null) return;

    try {
      await _service.goOffline(_currentAgentId!);
      state = state.copyWith(status: 'offline');
    } catch (e) {
      state = state.copyWith(error: 'Failed to go offline: ${e.toString()}');
    }
  }

  /// Set as busy
  Future<void> setBusy() async {
    if (_currentAgentId == null) return;

    try {
      await _service.setBusy(_currentAgentId!);
      state = state.copyWith(status: 'busy');
    } catch (e) {
      state = state.copyWith(error: 'Failed to set busy: ${e.toString()}');
    }
  }

  /// Set on break
  Future<void> setOnBreak() async {
    if (_currentAgentId == null) return;

    try {
      await _service.setOnBreak(_currentAgentId!);
      state = state.copyWith(status: 'on_break');
    } catch (e) {
      state = state.copyWith(error: 'Failed to set on break: ${e.toString()}');
    }
  }

  /// Update location
  Future<void> updateLocation(double latitude, double longitude) async {
    if (_currentAgentId == null) return;

    try {
      await _service.updateLocation(_currentAgentId!, latitude, longitude);
      state = state.copyWith(
        lastLocation: {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update location: ${e.toString()}');
    }
  }

  /// Accept an order
  Future<bool> acceptOrder(String orderId) async {
    try {
      final success = await _service.acceptOrder(orderId);
      if (success) {
        // Reload availability to get updated counts
        await _loadAvailability();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Failed to accept order: ${e.toString()}');
      return false;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final success = await _service.updateOrderStatus(orderId, newStatus);
      if (success) {
        // Reload availability to get updated counts
        await _loadAvailability();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update order status: ${e.toString()}');
      return false;
    }
  }

  /// Refresh availability data
  Future<void> refresh() async {
    await _loadAvailability();
  }
}

/// Provider for agent availability
final agentAvailabilityProvider = StateNotifierProvider<AgentAvailabilityNotifier, AgentAvailabilityState>((ref) {
  return AgentAvailabilityNotifier(AgentAvailabilityService());
});
