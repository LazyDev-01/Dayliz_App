import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/geofencing/enhanced_zone_detection_result.dart';

/// State for viewing mode management
class ViewingModeState {
  final bool isViewingMode;
  final bool canOrder;
  final String? restrictionMessage;
  final AccessLevel accessLevel;
  final DateTime? lastUpdated;
  final bool showRestrictionNotification;

  const ViewingModeState({
    this.isViewingMode = false,
    this.canOrder = true,
    this.restrictionMessage,
    this.accessLevel = AccessLevel.fullAccess,
    this.lastUpdated,
    this.showRestrictionNotification = false,
  });

  ViewingModeState copyWith({
    bool? isViewingMode,
    bool? canOrder,
    String? restrictionMessage,
    AccessLevel? accessLevel,
    DateTime? lastUpdated,
    bool? showRestrictionNotification,
    bool clearRestrictionMessage = false,
  }) {
    return ViewingModeState(
      isViewingMode: isViewingMode ?? this.isViewingMode,
      canOrder: canOrder ?? this.canOrder,
      restrictionMessage: clearRestrictionMessage ? null : (restrictionMessage ?? this.restrictionMessage),
      accessLevel: accessLevel ?? this.accessLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      showRestrictionNotification: showRestrictionNotification ?? this.showRestrictionNotification,
    );
  }

  /// Check if viewing mode should be refreshed (24 hours old)
  bool get shouldRefresh {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!).inHours >= 24;
  }
}

/// Notifier for viewing mode state management
class ViewingModeNotifier extends StateNotifier<ViewingModeState> {
  final SharedPreferences _prefs;
  
  static const String _viewingModeKey = 'viewing_mode_state';
  static const String _lastUpdatedKey = 'viewing_mode_last_updated';
  static const String _accessLevelKey = 'viewing_mode_access_level';
  static const String _restrictionMessageKey = 'viewing_mode_restriction_message';

  ViewingModeNotifier(this._prefs) : super(const ViewingModeState()) {
    _loadPersistedState();
  }

  /// Load persisted viewing mode state
  void _loadPersistedState() {
    try {
      final isViewingMode = _prefs.getBool(_viewingModeKey) ?? false;
      final lastUpdatedMs = _prefs.getInt(_lastUpdatedKey);
      final accessLevelIndex = _prefs.getInt(_accessLevelKey) ?? 0;
      final restrictionMessage = _prefs.getString(_restrictionMessageKey);

      final lastUpdated = lastUpdatedMs != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastUpdatedMs)
          : null;

      final accessLevel = AccessLevel.values[accessLevelIndex];

      state = ViewingModeState(
        isViewingMode: isViewingMode,
        canOrder: accessLevel == AccessLevel.fullAccess,
        restrictionMessage: restrictionMessage,
        accessLevel: accessLevel,
        lastUpdated: lastUpdated,
        showRestrictionNotification: isViewingMode && accessLevel == AccessLevel.viewingOnly,
      );
    } catch (e) {
      // If loading fails, start with default state
      state = const ViewingModeState();
    }
  }

  /// Update viewing mode based on enhanced zone detection result
  Future<void> updateFromZoneResult(EnhancedZoneDetectionResult result) async {
    final newState = ViewingModeState(
      isViewingMode: result.accessLevel == AccessLevel.viewingOnly,
      canOrder: result.canOrder,
      restrictionMessage: result.accessLevel == AccessLevel.viewingOnly ? result.message : null,
      accessLevel: result.accessLevel,
      lastUpdated: DateTime.now(),
      showRestrictionNotification: result.accessLevel == AccessLevel.viewingOnly,
    );

    state = newState;
    await _persistState();
  }

  /// Dismiss the restriction notification (user acknowledged it)
  Future<void> dismissRestrictionNotification() async {
    state = state.copyWith(showRestrictionNotification: false);
    // Don't persist this - we want to show it again on app restart
  }

  /// Clear viewing mode (when user gets delivery access)
  Future<void> clearViewingMode() async {
    state = const ViewingModeState(
      isViewingMode: false,
      canOrder: true,
      accessLevel: AccessLevel.fullAccess,
      lastUpdated: null,
      showRestrictionNotification: false,
    );
    await _clearPersistedState();
  }

  /// Force refresh viewing mode state
  Future<void> forceRefresh() async {
    state = state.copyWith(lastUpdated: null);
    await _prefs.remove(_lastUpdatedKey);
  }

  /// Persist state to SharedPreferences
  Future<void> _persistState() async {
    try {
      await Future.wait([
        _prefs.setBool(_viewingModeKey, state.isViewingMode),
        _prefs.setInt(_accessLevelKey, state.accessLevel.index),
        if (state.lastUpdated != null)
          _prefs.setInt(_lastUpdatedKey, state.lastUpdated!.millisecondsSinceEpoch),
        if (state.restrictionMessage != null)
          _prefs.setString(_restrictionMessageKey, state.restrictionMessage!)
        else
          _prefs.remove(_restrictionMessageKey),
      ]);
    } catch (e) {
      // Persistence failure shouldn't break the app
      debugPrint('Failed to persist viewing mode state: $e');
    }
  }

  /// Clear persisted state
  Future<void> _clearPersistedState() async {
    try {
      await Future.wait([
        _prefs.remove(_viewingModeKey),
        _prefs.remove(_lastUpdatedKey),
        _prefs.remove(_accessLevelKey),
        _prefs.remove(_restrictionMessageKey),
      ]);
    } catch (e) {
      debugPrint('Failed to clear viewing mode state: $e');
    }
  }
}

/// Provider for viewing mode state
final viewingModeProvider = StateNotifierProvider<ViewingModeNotifier, ViewingModeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ViewingModeNotifier(prefs);
});

/// Provider for SharedPreferences - will be overridden in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences provider must be overridden in main.dart');
});
