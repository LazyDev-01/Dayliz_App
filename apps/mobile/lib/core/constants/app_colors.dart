import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Standard Green (main theme)
  static const primary = Color(0xFF00AD48);        // Standard green for buttons and interactions
  static const primaryLight = Color(0xFF81C784);   // Light standard green
  static const primaryDark = Color(0xFF388E3C);    // Dark standard green
  static const forestGreen = Color(0xFF2E7D32);    // Dark forest green for navigation
  static const deepForestGreen = Color(0xFF1B5E20); // Very deep forest green
  
  // App bar specific colors - Bright Green
  static const appBarPrimary = Color(0xFFB5E853);  // Bright green for app bar only
  static const appBarLight = Color(0xFFD4F47A);    // Light bright green for app bar
  
  // Secondary colors - Sunny Yellow (grocery accent)
  static const secondary = Color(0xFFFFD54F);      // Sunny yellow (matches app bar)
  static const secondaryLight = Color(0xFFFFE082); // Light yellow
  static const secondaryDark = Color(0xFFFFC107);  // Deep yellow
  
  // Accent colors - Vibrant Orange (appetite appeal)
  static const accent = Color(0xFFFF9800);         // Vibrant orange
  static const accentLight = Color(0xFFFFB74D);    // Light orange
  static const accentDark = Color(0xFFF57C00);     // Deep orange
  
  // Neutral colors - Clean and modern
  static const background = Color(0xFFFFFFFF);     // Pure white background
  static const surface = Color(0xFFFFFFFF);        // Pure white
  static const surfaceVariant = Color(0xFFF7FCF0); // Light green-tinted surface
  
  // App bar specific colors for certain screens
  static const appBarSecondary = Color(0xFFFAFDF2); // Light green tint for categories, cart, product screens
  static const grey = Color(0xFF9E9E9E);
  static const greyLight = Color(0xFFF0F8E8);      // Light green-tinted grey
  static const greyDark = Color(0xFF616161);
  
  // Text colors - Enhanced contrast with green theme
  static const textPrimary = Color(0xFF1F2937);    // Dark gray for excellent readability
  static const textSecondary = Color(0xFF4B5563);  // Medium gray
  static const textTertiary = Color(0xFF757575);   // Standard grey
  static const textDisabled = Color(0xFFBDBDBD);
  static const textOnPrimary = Color(0xFF1F2937);  // Dark text on green primary
  
  // Semantic colors - Grocery-themed with green primary
  static const error = Color(0xFFE53935);          // Bright red for errors
  static const success = Color(0xFF4CAF50);        // Green for success (matches primary)
  static const info = Color(0xFF4CAF50);           // Standard green for information (matches primary)
  static const warning = Color(0xFFFF8F00);        // Orange for warnings
  static const locationBlue = Color(0xFF2196F3);   // Blue for location services
  
  // Grocery-specific semantic colors
  static const fresh = Color(0xFF4CAF50);          // Fresh produce (matches primary)
  static const organic = Color(0xFF388E3C);        // Organic products (darker green)
  static const premium = Color(0xFF673AB7);        // Premium products (purple)
  static const discount = Color(0xFFE91E63);       // Discounts and offers
  static const sale = Color(0xFFFF5722);           // Sale items
  static const newProduct = Color(0xFFFFD54F);     // New arrivals (sunny yellow)
  
  // Category colors for visual distinction
  static const categoryFruits = Color(0xFFFF6B6B);      // Red for fruits
  static const categoryVegetables = Color(0xFF4ECDC4);  // Teal for vegetables
  static const categoryDairy = Color(0xFFFFE66D);       // Yellow for dairy
  static const categoryMeat = Color(0xFFFF8A80);        // Light red for meat
  static const categoryBakery = Color(0xFFFFB74D);      // Orange for bakery
  static const categoryBeverages = Color(0xFF64B5F6);   // Light blue for beverages
  static const categorySnacks = Color(0xFFBA68C8);      // Purple for snacks
  static const categoryFrozen = Color(0xFF81D4FA);      // Light blue for frozen
  
  // UI element colors
  static const divider = Color(0xFFF0F8E8);        // Light green divider
  static const cardShadow = Color(0x1AB5E853);     // Green-tinted shadow
  static const ratingStarFilled = Color(0xFFFFD54F); // Sunny yellow stars
  static const ratingStarEmpty = Color(0xFFE0E0E0);
  static const shimmerBase = Color(0xFFF7FCF0);    // Light green shimmer
  static const shimmerHighlight = Color(0xFFFFFFFF);
  
  // Gradient colors for modern appeal
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // App bar specific gradient - Bright Green
  static const gradientAppBar = LinearGradient(
    colors: [Color(0xFFB5E853), Color(0xFF8BC34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const gradientSecondary = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const gradientBackground = LinearGradient(
    colors: [Color(0xFFFAFDF2), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const gradientCard = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FCF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Status colors for orders and delivery
  static const statusPending = Color(0xFFFF9800);     // Orange for pending
  static const statusConfirmed = Color(0xFF4CAF50);   // Standard green for confirmed (matches primary)
  static const statusPreparing = Color(0xFFFF5722);   // Red-orange for preparing
  static const statusOutForDelivery = Color(0xFF9C27B0); // Purple for out for delivery
  static const statusDelivered = Color(0xFF4CAF50);   // Green for delivered (matches primary)
  static const statusCancelled = Color(0xFF757575);   // Grey for cancelled
  
  // Special occasion colors
  static const festive = Color(0xFFE91E63);           // Pink for festivals
  static const seasonal = Color(0xFFFF5722);          // Orange for seasonal
  static const limitedTime = Color(0xFF9C27B0);       // Purple for limited time
  
  // Accessibility colors
  static const highContrast = Color(0xFF000000);      // Black for high contrast
  static const focusIndicator = Color(0xFF4CAF50);    // Standard green for focus (matches primary)
  static const selectionBackground = Color(0xFFF0F8E8); // Light green for selection
} 