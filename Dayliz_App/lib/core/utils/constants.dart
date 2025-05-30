import 'package:flutter/material.dart';

/// App-wide constants class for standardization
class AppConstants {
  // API related constants
  static const String apiBaseUrl = 'https://api.dayliz.com';
  static const int defaultPageSize = 20;
  static const int apiRequestTimeout = 30; // seconds
  
  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enablePushNotifications = true;
  
  // Pagination
  static const int itemsPerPage = 10;
  
  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Cache durations
  static const Duration cacheDuration = Duration(hours: 4);
  
  // Regular Expressions
  static final RegExp emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );
  
  static final RegExp passwordRegExp = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
  );
  
  static final RegExp phoneRegExp = RegExp(
    r'^\+?[0-9]{10,15}$',
  );
  
  // Debounce durations
  static const Duration searchDebounce = Duration(milliseconds: 500);
  
  // App dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  
  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeHeading = 22.0;
  static const double fontSizeTitle = 20.0;
  
  // Button sizes
  static const double buttonHeight = 50.0;
  static const double smallButtonHeight = 36.0;
  
  // Image dimensions
  static const double productCardImageHeight = 180.0;
  static const double categoryIconSize = 40.0;
  static const double avatarSize = 40.0;
  
  // Max constraints
  static const int maxPasswordLength = 32;
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxAddressLength = 200;
  static const int maxPhoneLength = 15;
  
  // App specific
  static const int maxItemsInCart = 20;
  static const int maxItemQuantity = 10;
  static const String currencySymbol = '₹';
}

/// App colors
class AppColors {
  // Primary colors
  static const Color primaryColor = Color(0xFF3F51B5);
  static const Color primaryLightColor = Color(0xFF757DE8);
  static const Color primaryDarkColor = Color(0xFF002984);
  
  // Secondary colors
  static const Color secondaryColor = Color(0xFFFF4081);
  static const Color secondaryLightColor = Color(0xFFFF79B0);
  static const Color secondaryDarkColor = Color(0xFFC60055);
  
  // Background colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color dialogColor = Colors.white;
  
  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);
  
  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Divider and border colors
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color borderColor = Color(0xFFE0E0E0);
  
  // Feature colors
  static const Color discountBadgeColor = Color(0xFFE53935);
  static const Color ratingStarColor = Color(0xFFFFC107);
  static const Color addToCartColor = Color(0xFF4CAF50);
  static const Color buyNowColor = Color(0xFF3F51B5);
  
  // Misc
  static const Color shimmerBaseColor = Color(0xFFEEEEEE);
  static const Color shimmerHighlightColor = Color(0xFFFAFAFA);
} 