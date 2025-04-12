import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A provider that manages the app's theme mode.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load the saved theme mode from shared preferences.
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString('theme_mode');
      
      if (savedThemeMode != null) {
        state = _stringToThemeMode(savedThemeMode);
      }
    } catch (e) {
      // Fallback to system theme if loading fails
      state = ThemeMode.system;
    }
  }

  /// Save the theme mode to shared preferences.
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', _themeModeToString(mode));
    } catch (e) {
      // Ignore errors when saving
    }
  }

  /// Set the theme mode and save it to shared preferences.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _saveThemeMode(mode);
  }

  /// Toggle between light and dark themes.
  Future<void> toggleThemeMode() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Convert a string to a ThemeMode.
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Convert a ThemeMode to a string.
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

/// Provider for the app's theme mode.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
}); 