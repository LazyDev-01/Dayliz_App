import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class AppTextStyles {
  // Headlines
  static const TextStyle headline1 = TextStyle(
    fontSize: AppDimensions.fontDisplay,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: AppDimensions.fontXxl,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: AppDimensions.fontXl,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppDimensions.fontL,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppDimensions.fontM,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppDimensions.fontS,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyXSmall = TextStyle(
    fontSize: AppDimensions.fontXs,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Button text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: AppDimensions.fontM,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.5,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: AppDimensions.fontS,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.5,
  );

  // Label text
  static const TextStyle labelLarge = TextStyle(
    fontSize: AppDimensions.fontM,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: AppDimensions.fontS,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: AppDimensions.fontXs,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Special text styles
  static const TextStyle price = TextStyle(
    fontSize: AppDimensions.fontL,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    height: 1.5,
  );

  static const TextStyle discountPrice = TextStyle(
    fontSize: AppDimensions.fontM,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    decoration: TextDecoration.lineThrough,
    height: 1.5,
  );

  static const TextStyle error = TextStyle(
    fontSize: AppDimensions.fontXs,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
    height: 1.5,
  );

  static const TextStyle link = TextStyle(
    fontSize: AppDimensions.fontM,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    height: 1.5,
  );
} 