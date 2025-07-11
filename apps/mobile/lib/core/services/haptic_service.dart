import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive haptic feedback service for consistent user experience
/// 
/// Provides centralized haptic feedback management with:
/// - Different feedback intensities (light, medium, heavy)
/// - Global enable/disable functionality
/// - Callback wrapper methods
/// - Platform-aware implementation
/// - Debug logging for development
class HapticService {
  /// Global flag to enable/disable haptic feedback
  static bool _isEnabled = true;
  
  /// Debug flag for development logging
  static bool _debugMode = kDebugMode;

  /// Enable or disable haptic feedback globally
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (_debugMode) {
      debugPrint('🔄 HapticService: ${enabled ? 'Enabled' : 'Disabled'}');
    }
  }

  /// Check if haptic feedback is currently enabled
  static bool get isEnabled => _isEnabled;

  /// Enable debug logging
  static void setDebugMode(bool debug) {
    _debugMode = debug;
  }

  // MARK: - Basic Haptic Methods

  /// Light haptic feedback - for subtle interactions
  /// Use for: List item taps, button presses, navigation
  static void light() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.lightImpact();
      if (_debugMode) {
        debugPrint('🔸 HapticService: Light impact triggered');
      }
    } catch (e) {
      if (_debugMode) {
        debugPrint('⚠️ HapticService: Light impact failed - $e');
      }
    }
  }

  /// Medium haptic feedback - for important interactions
  /// Use for: Form submissions, confirmations, warnings
  static void medium() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.mediumImpact();
      if (_debugMode) {
        debugPrint('🔹 HapticService: Medium impact triggered');
      }
    } catch (e) {
      if (_debugMode) {
        debugPrint('⚠️ HapticService: Medium impact failed - $e');
      }
    }
  }

  /// Heavy haptic feedback - for critical interactions
  /// Use for: Destructive actions, errors, major state changes
  static void heavy() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.heavyImpact();
      if (_debugMode) {
        debugPrint('🔺 HapticService: Heavy impact triggered');
      }
    } catch (e) {
      if (_debugMode) {
        debugPrint('⚠️ HapticService: Heavy impact failed - $e');
      }
    }
  }

  /// Selection haptic feedback - for picker/selector interactions
  /// Use for: Dropdown selections, tab switches, slider changes
  static void selection() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.selectionClick();
      if (_debugMode) {
        debugPrint('🎯 HapticService: Selection click triggered');
      }
    } catch (e) {
      if (_debugMode) {
        debugPrint('⚠️ HapticService: Selection click failed - $e');
      }
    }
  }

  // MARK: - Callback Wrapper Methods

  /// Wraps a VoidCallback with light haptic feedback
  static VoidCallback wrapLight(VoidCallback callback) {
    return () {
      light();
      callback();
    };
  }

  /// Wraps a VoidCallback with medium haptic feedback
  static VoidCallback wrapMedium(VoidCallback callback) {
    return () {
      medium();
      callback();
    };
  }

  /// Wraps a VoidCallback with heavy haptic feedback
  static VoidCallback wrapHeavy(VoidCallback callback) {
    return () {
      heavy();
      callback();
    };
  }

  /// Wraps a VoidCallback with selection haptic feedback
  static VoidCallback wrapSelection(VoidCallback callback) {
    return () {
      selection();
      callback();
    };
  }

  // MARK: - Convenience Methods

  /// Smart haptic feedback based on action type
  static void smart(HapticType type) {
    switch (type) {
      case HapticType.light:
        light();
        break;
      case HapticType.medium:
        medium();
        break;
      case HapticType.heavy:
        heavy();
        break;
      case HapticType.selection:
        selection();
        break;
    }
  }

  /// Wraps a callback with smart haptic feedback
  static VoidCallback wrap(VoidCallback callback, [HapticType type = HapticType.light]) {
    return () {
      smart(type);
      callback();
    };
  }
}

/// Enum for different haptic feedback types
enum HapticType {
  /// Light feedback for subtle interactions
  light,
  
  /// Medium feedback for important interactions
  medium,
  
  /// Heavy feedback for critical interactions
  heavy,
  
  /// Selection feedback for picker/selector interactions
  selection,
}

/// Extension methods for easy haptic integration
extension HapticCallback on VoidCallback {
  /// Adds light haptic feedback to any VoidCallback
  VoidCallback get withLightHaptic => HapticService.wrapLight(this);
  
  /// Adds medium haptic feedback to any VoidCallback
  VoidCallback get withMediumHaptic => HapticService.wrapMedium(this);
  
  /// Adds heavy haptic feedback to any VoidCallback
  VoidCallback get withHeavyHaptic => HapticService.wrapHeavy(this);
  
  /// Adds selection haptic feedback to any VoidCallback
  VoidCallback get withSelectionHaptic => HapticService.wrapSelection(this);
  
  /// Adds custom haptic feedback to any VoidCallback
  VoidCallback withHaptic([HapticType type = HapticType.light]) {
    return HapticService.wrap(this, type);
  }
}
