import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Theme Extension for custom properties
class DaylizThemeExtension extends ThemeExtension<DaylizThemeExtension> {
  final Color accentSecondary;
  final Color cardBackground;
  final Color success;
  final Color info;
  final Color warning;
  final Color error;
  final BorderRadius cardBorderRadius;
  final BorderRadius buttonBorderRadius;
  final BorderRadius inputBorderRadius;
  final Map<String, double> spacing;
  final double baseBorderRadius;

  DaylizThemeExtension({
    required this.accentSecondary,
    required this.cardBackground,
    required this.success,
    required this.info,
    required this.warning,
    required this.error,
    required this.cardBorderRadius,
    required this.buttonBorderRadius,
    required this.inputBorderRadius,
    required this.spacing,
    required this.baseBorderRadius,
  });

  @override
  ThemeExtension<DaylizThemeExtension> copyWith({
    Color? accentSecondary,
    Color? cardBackground,
    Color? success,
    Color? info,
    Color? warning,
    Color? error,
    BorderRadius? cardBorderRadius,
    BorderRadius? buttonBorderRadius,
    BorderRadius? inputBorderRadius,
    Map<String, double>? spacing,
    double? baseBorderRadius,
  }) {
    return DaylizThemeExtension(
      accentSecondary: accentSecondary ?? this.accentSecondary,
      cardBackground: cardBackground ?? this.cardBackground,
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      inputBorderRadius: inputBorderRadius ?? this.inputBorderRadius,
      spacing: spacing ?? this.spacing,
      baseBorderRadius: baseBorderRadius ?? this.baseBorderRadius,
    );
  }

  @override
  ThemeExtension<DaylizThemeExtension> lerp(
      covariant ThemeExtension<DaylizThemeExtension>? other, double t) {
    if (other is! DaylizThemeExtension) return this;

    return DaylizThemeExtension(
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      cardBorderRadius: BorderRadius.lerp(cardBorderRadius, other.cardBorderRadius, t)!,
      buttonBorderRadius: BorderRadius.lerp(buttonBorderRadius, other.buttonBorderRadius, t)!,
      inputBorderRadius: BorderRadius.lerp(inputBorderRadius, other.inputBorderRadius, t)!,
      spacing: t < 0.5 ? spacing : other.spacing,
      baseBorderRadius: lerpDouble(baseBorderRadius, other.baseBorderRadius, t)!,
    );
  }

  // Helper for lerping doubles
  static double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  // Light theme extension
  static DaylizThemeExtension get light => DaylizThemeExtension(
    accentSecondary: const Color(0xFFFF9800),
    cardBackground: Colors.white,
    success: const Color(0xFF4CAF50),
    info: const Color(0xFF2196F3),
    warning: const Color(0xFFFFC107),
    error: const Color(0xFFF44336),
    cardBorderRadius: BorderRadius.circular(12),
    buttonBorderRadius: BorderRadius.circular(8),
    inputBorderRadius: BorderRadius.circular(8),
    spacing: {
      'xs': 4.0,
      'sm': 8.0,
      'md': 16.0,
      'lg': 24.0,
      'xl': 32.0,
      'xxl': 48.0,
    },
    baseBorderRadius: 8.0,
  );

  // Dark theme extension
  static DaylizThemeExtension get dark => DaylizThemeExtension(
    accentSecondary: const Color(0xFFFFB74D),
    cardBackground: const Color(0xFF1E1E1E),
    success: const Color(0xFF81C784),
    info: const Color(0xFF64B5F6),
    warning: const Color(0xFFFFD54F),
    error: const Color(0xFFE57373),
    cardBorderRadius: BorderRadius.circular(12),
    buttonBorderRadius: BorderRadius.circular(8),
    inputBorderRadius: BorderRadius.circular(8),
    spacing: {
      'xs': 4.0,
      'sm': 8.0,
      'md': 16.0,
      'lg': 24.0,
      'xl': 32.0,
      'xxl': 48.0,
    },
    baseBorderRadius: 8.0,
  );
}

class AppTheme {
  // App Colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color primaryDarkColor = Color(0xFF388E3C);
  static const Color primaryLightColor = Color(0xFFC8E6C9);
  static const Color accentColor = Color(0xFFFFC107);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFBDBDBD);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color greyColor = Color(0xFFE0E0E0);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);

  // Typography
  static TextTheme get _baseTextTheme => GoogleFonts.poppinsTextTheme();

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge!.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 28.0,
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium!.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 24.0,
      ),
      displaySmall: base.displaySmall!.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 22.0,
      ),
      headlineMedium: base.headlineMedium!.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
      ),
      headlineSmall: base.headlineSmall!.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18.0,
      ),
      titleLarge: base.titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
      ),
      titleMedium: base.titleMedium!.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15.0,
      ),
      titleSmall: base.titleSmall!.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      ),
      bodyLarge: base.bodyLarge!.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 15.0,
      ),
      bodyMedium: base.bodyMedium!.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
      ),
      bodySmall: base.bodySmall!.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
      ),
      labelLarge: base.labelLarge!.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      ),
      labelMedium: base.labelMedium!.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 12.0,
      ),
      labelSmall: base.labelSmall!.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 10.0,
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    final ThemeData base = ThemeData.light();
    final textTheme = _buildTextTheme(_baseTextTheme);

    return base.copyWith(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        background: Colors.white,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        color: Colors.white,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1.5,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
      extensions: [
        DaylizThemeExtension.light,
      ],
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final ThemeData base = ThemeData.dark();
    final textTheme = _buildTextTheme(_baseTextTheme);

    return base.copyWith(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        color: Color(0xFF1E1E1E),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1.5,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFFAAAAAA),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
      ),
      extensions: [
        DaylizThemeExtension.dark,
      ],
    );
  }
} 