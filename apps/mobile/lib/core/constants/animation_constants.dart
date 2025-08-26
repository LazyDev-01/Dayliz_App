import 'package:flutter/material.dart';

/// Animation constants for consistent timing and behavior across the app
class AnimationConstants {
  // Animation Durations
  static const Duration veryFast = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration verySlow = Duration(milliseconds: 1200);

  // Lottie Animation Paths
  static const String _animationsPath = 'assets/animations/';
  
  // Loading Animations
  static const String splashLogo = '${_animationsPath}loading/splash_logo.json';
  static const String loadingAnimation = '${_animationsPath}loading_animation.json';
  static const String locationDetection = '${_animationsPath}loaction_detection.json';
  static const String skeletonLoading = '${_animationsPath}loading/skeleton_loading.json';
  static const String searchLoading = '${_animationsPath}loading/search_loading.json';
  static const String pageLoading = '${_animationsPath}loading/page_loading.json';
  
  // Interaction Animations
  static const String addToCart = '${_animationsPath}interactions/add_to_cart.json';
  static const String heartLike = '${_animationsPath}interactions/heart_like.json';
  static const String successCheckmark = '${_animationsPath}success_checkmark.json';
  static const String errorAnimation = '${_animationsPath}network_error.json';
  static const String buttonPress = '${_animationsPath}interactions/button_press.json';
  
  // Empty State Animations
  static const String emptyCart = '${_animationsPath}empty_cart.json';
  static const String noOrders = '${_animationsPath}empty_states/no_orders.json';
  static const String noInternet = '${_animationsPath}network_error.json';
  static const String noSearchResults = '${_animationsPath}no_products_found.json';
  static const String emptyWishlist = '${_animationsPath}empty_states/empty_wishlist.json';
  
  // Navigation Animations
  static const String homeIcon = '${_animationsPath}navigation/home_icon.json';
  static const String categoriesIcon = '${_animationsPath}navigation/categories_icon.json';
  static const String cartIcon = '${_animationsPath}navigation/cart_icon.json';
  static const String ordersIcon = '${_animationsPath}navigation/orders_icon.json';
  
  // Order Tracking Animations
  static const String orderPreparing = '${_animationsPath}order_tracking/preparing.json';
  static const String outForDelivery = '${_animationsPath}order_tracking/out_for_delivery.json';
  static const String orderDelivered = '${_animationsPath}order_tracking/delivered.json';
  static const String orderConfirmed = '${_animationsPath}order_tracking/confirmed.json';
  
  // Celebration Animations
  static const String confetti = '${_animationsPath}celebrations/confetti.json';
  static const String fireworks = '${_animationsPath}celebrations/fireworks.json';
  static const String partyPopper = '${_animationsPath}celebrations/party_popper.json';
  
  // Animation Curves
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.easeOutBack;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  
  // Animation Sizes (Updated for better performance)
  static const double smallSize = 24.0;
  static const double mediumSize = 48.0;
  static const double largeSize = 90.0;  // Reduced from 96 to 90
  static const double extraLargeSize = 120.0;  // Reduced from 150 to 120
  
  // Animation Repeat Counts
  static const int noRepeat = 1;
  static const int infiniteRepeat = -1;
  static const int shortRepeat = 3;
  
  // Performance Settings
  static const bool enableAnimationsOnLowEndDevices = false;
  static const int maxConcurrentAnimations = 5;
  static const double animationQualityThreshold = 0.8; // For performance scaling
}

/// Animation configuration for different device performance levels
enum AnimationQuality {
  low,
  medium,
  high,
}

/// Animation presets for common use cases
class AnimationPresets {
  // Quick feedback animations
  static const Duration quickFeedback = AnimationConstants.fast;
  static const Curve quickFeedbackCurve = AnimationConstants.emphasizedCurve;
  
  // Loading state animations
  static const Duration loadingState = AnimationConstants.medium;
  static const Curve loadingCurve = AnimationConstants.standardCurve;
  
  // Success/Error feedback
  static const Duration statusFeedback = AnimationConstants.slow;
  static const Curve statusCurve = AnimationConstants.bounceCurve;
  
  // Page transitions
  static const Duration pageTransition = AnimationConstants.medium;
  static const Curve pageTransitionCurve = AnimationConstants.standardCurve;
  
  // Micro-interactions
  static const Duration microInteraction = AnimationConstants.veryFast;
  static const Curve microInteractionCurve = AnimationConstants.emphasizedCurve;
}
