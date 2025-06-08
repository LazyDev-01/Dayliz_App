import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppTheme {
  // Primary Colors - Updated to use blue-themed grocery palette
  static const Color primaryColor = AppColors.primary;
  static const Color primaryLightColor = AppColors.primaryLight;
  static const Color primaryDarkColor = AppColors.primaryDark;
  
  // Secondary Colors - Updated to use blue-themed grocery palette
  static const Color secondaryColor = AppColors.secondary;
  static const Color secondaryLightColor = AppColors.secondaryLight;
  static const Color secondaryDarkColor = AppColors.secondaryDark;
  
  // Neutral Colors - Updated to use blue-themed grocery palette
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color errorColor = AppColors.error;
  
  // Text Colors - Updated to use blue-themed grocery palette
  static const Color textPrimaryColor = AppColors.textPrimary;
  static const Color textSecondaryColor = AppColors.textSecondary;
  static const Color textDisabledColor = AppColors.textDisabled;
  
  // Status Colors - Updated to use blue-themed grocery palette
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color infoColor = AppColors.info;
  
  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Color(0xFFE0E0E0);
  
  // Theme Data
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.black,
      error: errorColor,
      onError: Colors.white,
      background: backgroundColor,
      onBackground: textPrimaryColor,
      surface: surfaceColor,
      onSurface: textPrimaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: textDisabledColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textPrimaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textPrimaryColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryLightColor,
      onPrimary: Colors.black,
      secondary: secondaryColor,
      onSecondary: Colors.black,
      error: errorColor,
      onError: Colors.white,
      background: darkBackgroundColor,
      onBackground: darkTextColor,
      surface: darkSurfaceColor,
      onSurface: darkTextColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurfaceColor,
      foregroundColor: darkTextColor,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: darkSurfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: primaryLightColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLightColor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLightColor,
        side: const BorderSide(color: primaryLightColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryLightColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      fillColor: darkSurfaceColor,
      filled: true,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: darkTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkTextColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkTextColor,
      ),
    ),
  );
}

// Spacing utility class
class AppSpacing {
  // Vertical Spacing
  static const SizedBox vXS = SizedBox(height: 4);
  static const SizedBox vSM = SizedBox(height: 8);
  static const SizedBox vMD = SizedBox(height: 16);
  static const SizedBox vLG = SizedBox(height: 24);
  static const SizedBox vXL = SizedBox(height: 32);
  static const SizedBox v2XL = SizedBox(height: 48);
  
  // Horizontal Spacing
  static const SizedBox hXS = SizedBox(width: 4);
  static const SizedBox hSM = SizedBox(width: 8);
  static const SizedBox hMD = SizedBox(width: 16);
  static const SizedBox hLG = SizedBox(width: 24);
  static const SizedBox hXL = SizedBox(width: 32);
  static const SizedBox h2XL = SizedBox(width: 48);
  
  // Padding
  static const EdgeInsets paddingXS = EdgeInsets.all(4);
  static const EdgeInsets paddingSM = EdgeInsets.all(8);
  static const EdgeInsets paddingMD = EdgeInsets.all(16);
  static const EdgeInsets paddingLG = EdgeInsets.all(24);
  static const EdgeInsets paddingXL = EdgeInsets.all(32);
  
  // Padding Horizontal
  static const EdgeInsets paddingHXS = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets paddingHSM = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets paddingHMD = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets paddingHLG = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets paddingHXL = EdgeInsets.symmetric(horizontal: 32);
  
  // Padding Vertical
  static const EdgeInsets paddingVXS = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets paddingVSM = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingVMD = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets paddingVLG = EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets paddingVXL = EdgeInsets.symmetric(vertical: 32);
  
  // Border Radius
  static final BorderRadius borderRadiusXS = BorderRadius.circular(4);
  static final BorderRadius borderRadiusSM = BorderRadius.circular(8);
  static final BorderRadius borderRadiusMD = BorderRadius.circular(12);
  static final BorderRadius borderRadiusLG = BorderRadius.circular(16);
  static final BorderRadius borderRadiusXL = BorderRadius.circular(24);
} 